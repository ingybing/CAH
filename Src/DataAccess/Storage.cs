using CardsAgainstHumanity.DataAccess.Documents;

using MongoDB.Bson;
using MongoDB.Driver;
using System.Linq;
using System;
using System.Collections.Generic;

namespace CardsAgainstHumanity.DataAccess
{
    public class Storage
    {
        private IMongoDatabase db;
        private MongoClient mongoDb;

        public Storage()
        {
            this.mongoDb = new MongoClient("mongodb://localhost");
            this.db = mongoDb.GetDatabase("CardsAgainstHumanity");
        }

        public void ImportCards(string[] lines, CardType cardType)
        {
            var cards = lines.Select(x => new Card
            {
                Type = cardType,
                Text = cardType == CardType.White ? x : x.Split('^')[1],
                Pick = cardType == CardType.White ? 0 : int.Parse(x.Split('^')[0]),
                PlayerHandId = null,
                LastSeen = null
            });

            var collectionName = string.Format("{0}Card", cardType.ToString());

            var collectionExists = this.db.ListCollections(new ListCollectionsOptions { Filter = new BsonDocument("name", collectionName) }).Any();
            var cardCollection = this.db.GetCollection<Card>(collectionName);

            if (!collectionExists)
            {
                var indexKeys = Builders<Card>.IndexKeys.Ascending("LastSeen");
                var indexOptions = new CreateIndexOptions { Name = "LastSeenIndex" };

                cardCollection.Indexes.CreateOne(indexKeys, indexOptions);
            }

            cardCollection.InsertMany(cards);
        }

        public Card DrawBlackCard(ObjectId playerId)
        {
            if(!this.GetPlayer(playerId).IsTsar)
            {
                throw new Exception("Only the TSAR can draw a black card");
            }

            var blackCards = this.db.GetCollection<Card>("BlackCard");
            var index = new Random().Next(9);
            var blackCard = blackCards.AsQueryable().OrderBy(x => x.LastSeen).Take(10).ToList().ElementAt(index);

            var filter = Builders<Card>.Filter.Eq("Id", blackCard.Id);
            var update = Builders<Card>.Update.Set("LastSeen", DateTime.Now);

            blackCards.UpdateOne(filter, update);
            return blackCard;
        }

        public Card GetBlackCard()
        {
            var blackCards = this.db.GetCollection<Card>("BlackCard");
            var blackCard = blackCards.AsQueryable().OrderByDescending(x => x.LastSeen).Take(1).SingleOrDefault();
            
            return blackCard;
        }

        public IList<Card> ExchangeCards(List<ObjectId> list)
        {
            var whiteCards = this.db.GetCollection<Card>("WhiteCard");
            var machingCards = whiteCards.AsQueryable().Where(x => list.Contains(x.Id));
            var playerId = machingCards.Select(x => x.PlayerHandId).Distinct().Single().Value;

            var filter = Builders<Card>.Filter.In<ObjectId>("Id", list);
            var update = Builders<Card>.Update.Set<ObjectId?>("PlayerHandId", null);

            whiteCards.UpdateMany(filter, update);

            var newCards = this.DrawWhiteCards(whiteCards, list.Count, playerId);
            return newCards;
        }

        public IList<Card> GetPlayedCards()
        {
            var whiteCards = this.db.GetCollection<Card>("WhiteCard");
            return whiteCards.AsQueryable().Where(x => x.Played).OrderBy(x => x.PlayerHandId).ThenBy(x => x.Order).ToList();
        }

        public Player GetPlayer(ObjectId id)
        {
            var players = this.db.GetCollection<Player>("Player");
            var player = players.AsQueryable().SingleOrDefault(x => x.Id == id);
            return player;
        }

        private IList<Card> DrawWhiteCards(IMongoCollection<Card> whiteCards, int numberOfCardsToDraw, ObjectId playerId)
        {
            var cards = new List<Card>();
            var top50 = whiteCards.AsQueryable().OrderBy(x => x.LastSeen).Take(50).ToList();
            var random = new Random();
            var previousIndexes = new List<int>();

            while (cards.Count < numberOfCardsToDraw)
            {
                var index = random.Next(49);
                if (!previousIndexes.Contains(index))
                {
                    previousIndexes.Add(index);
                    var whiteCard = top50.ElementAt(index);
                    cards.Add(whiteCard);

                    var filter = Builders<Card>.Filter.Eq("Id", whiteCard.Id);
                    var update1 = Builders<Card>.Update.Set("LastSeen", DateTime.Now);
                    var update2 = Builders<Card>.Update.Set("PlayerHandId", playerId);
                    var update = Builders<Card>.Update.Combine(new[] { update1, update2 });

                    whiteCards.UpdateOne(filter, update);
                }
            }

            return cards;
        }

        public bool IsRoundFinished()
        {
            var whiteCards = this.db.GetCollection<Card>("WhiteCard");
            var haveAnyCardsBeenPlayed = whiteCards.AsQueryable().Any(x => x.Played);
            return !haveAnyCardsBeenPlayed;
        }

        public void PlayCard(ObjectId playerId, IList<ObjectId> cards)
        {
            var whiteCards = this.db.GetCollection<Card>("WhiteCard");
            var order = 1;
            foreach (var cardId in cards)
            {
                var whiteCard = whiteCards.AsQueryable().Single(x => x.PlayerHandId == playerId && x.Id == cardId);

                var filter = Builders<Card>.Filter.Eq("Id", whiteCard.Id);
                var updatePlayed = Builders<Card>.Update.Set("Played", true);
                var updateOrder = Builders<Card>.Update.Set("Order", order);
                var update = Builders<Card>.Update.Combine(updatePlayed, updateOrder);

                whiteCards.UpdateOne(filter, update);
                order++;
            }
        }

        public IList<Card> GetWhiteCards(ObjectId playerId)
        {
            const int CardsToDraw = 6;

            // Check and make sure the player isn't the Tsar.
            var players = this.db.GetCollection<Player>("Player");
            if(players.AsQueryable().Single(x=>x.Id == playerId).IsTsar)
            {
                return new List<Card>();
            }

            // Get the cards already in their hand if any.
            var whiteCards = this.db.GetCollection<Card>("WhiteCard");
            var existingWhiteCardsInHand = whiteCards.AsQueryable().Where(x => x.PlayerHandId == playerId).ToList();
            if(existingWhiteCardsInHand.Any())
            {
                var cardsInHand = existingWhiteCardsInHand.Count;
                if (cardsInHand < CardsToDraw)
                {
                    var delta = CardsToDraw - cardsInHand;
                    var deltaCards = this.DrawWhiteCards(whiteCards, delta, playerId);
                    return existingWhiteCardsInHand.Union(deltaCards).ToList();
                }

                return existingWhiteCardsInHand;
            }
            else
            { 
                // If no cards, from the top 50 unseen cards pick 'n'.
                var hand = this.DrawWhiteCards(whiteCards, CardsToDraw, playerId);
                return hand;
            }
        }

        public IList<Player> GetPlayers()
        {
            var players = this.db.GetCollection<Player>("Player").AsQueryable().ToList();
            return players;
        }

        public void ResetForNewGame()
        {
            this.db.DropCollection("Player");

            var whiteCards = this.db.GetCollection<Card>("WhiteCard");

            var filter = Builders<Card>.Filter.Ne("PlayerHandId", BsonNull.Value);

            var updatePlayerHandId = Builders<Card>.Update.Set("PlayerHandId", BsonNull.Value);
            var updatePlayed = Builders<Card>.Update.Set("Played", false);
            var updateOrder = Builders<Card>.Update.Set("Order", 0);
            var update = Builders<Card>.Update.Combine(updatePlayerHandId, updatePlayed, updateOrder);

            whiteCards.UpdateMany(filter, update);
        }

        public IList<Player> GetWinner()
        {
            var players = this.db.GetCollection<Player>("Player");
            var topScore = players.AsQueryable().Select(x => x.Points).Max();

            var result = players.AsQueryable().Where(x => x.Points == topScore).ToList();
            return result;
        }

        public Player GetTsar()
        {
            var players = this.db.GetCollection<Player>("Player");
            var tsar = players.AsQueryable().Single(x => x.IsTsar);
            return tsar;
        }

        public void SelectWinner(ObjectId tsar, ObjectId cardId)
        {
            var whiteCards = this.db.GetCollection<Card>("WhiteCard");
            var winningCard = whiteCards.AsQueryable().Single(x => x.Id == cardId);

            var players = this.db.GetCollection<Player>("Player");
            var currentTsar = players.AsQueryable().Single(x => x.IsTsar);
            if(currentTsar.Id == tsar)
            { 
                this.IncrementPlayerPoints(players, winningCard.PlayerHandId.Value);
                this.SelectNextTsar(players, currentTsar);
                this.ResetWhiteCardProperties(whiteCards);
            }
            else
            {
                throw new Exception("You are not the current TSAR!");
            }
        }

        private void ResetWhiteCardProperties(IMongoCollection<Card> whiteCards)
        {
            var filter = Builders<Card>.Filter.Eq("Played", true);
            var updatePlayed = Builders<Card>.Update.Set("Played", false);
            var updateOrder = Builders<Card>.Update.Set("Order", 0);
            var updatePlayerHandId = Builders<Card>.Update.Set<string>("PlayerHandId", null);
            var update = Builders<Card>.Update.Combine(updatePlayed, updatePlayerHandId, updateOrder);

            whiteCards.UpdateMany(filter, update);
        }

        private void SelectNextTsar(IMongoCollection<Player> players, Player currentTsar)
        {
            var nextTsar = players.AsQueryable().SingleOrDefault(x => x.TsarSequence == currentTsar.TsarSequence + 1);
            if(nextTsar == null)
            {
                nextTsar = players.AsQueryable().Single(x => x.TsarSequence == 0);
            }

            var currentTsarFilter = Builders<Player>.Filter.Eq<ObjectId>("Id", currentTsar.Id);
            var currentTsarUpdate = Builders<Player>.Update.Set<bool>("IsTsar", false);

            players.UpdateOne(currentTsarFilter, currentTsarUpdate);
            
            var nextTsarFilter = Builders<Player>.Filter.Eq<ObjectId>("Id", nextTsar.Id);
            var nextTsarUpdate = Builders<Player>.Update.Set<bool>("IsTsar", true);

            players.UpdateOne(nextTsarFilter, nextTsarUpdate);
        }

        private void IncrementPlayerPoints(IMongoCollection<Player> players, ObjectId winner)
        {
            var currentPoints = players.AsQueryable().Where(x => x.Id == winner).Select(x => x.Points).Single();

            var filter = Builders<Player>.Filter.Eq<ObjectId>("Id", winner);
            var update = Builders<Player>.Update.Set<int>("Points", currentPoints + 1);

            players.UpdateOne(filter, update);
        }

        public void NewGame()
        {
            this.db.DropCollection("Player");

            var filter = Builders<Card>.Filter.Ne<ObjectId?>("PlayerHandId", null);
            var update = Builders<Card>.Update.Set<ObjectId?>("PlayerHandId", null);
            
            var blackCards = this.db.GetCollection<Card>("BlackCard");
            var whiteCards = this.db.GetCollection<Card>("WhiteCard");

            blackCards.UpdateMany(filter, update);
            whiteCards.UpdateMany(filter, update);
        }

        public Player AddPlayer(string name)
        {
            var players = this.db.GetCollection<Player>("Player");
            var playerExists = players.AsQueryable().Any(x => x.Name.ToLower() == name.ToLower());

            if(playerExists)
            {
                throw new Exception("Player Already Exists");
            }

            var tsarSequenceId = 0;

            if (players.AsQueryable().Any())
            {
                var maxTsarSequenceId = players.AsQueryable().Max(x => x.TsarSequence);
                tsarSequenceId = maxTsarSequenceId + 1;
            }

            var isTsar = tsarSequenceId == 0;

            var newPlayer = new Player { Name = name, Points = 0, TsarSequence = tsarSequenceId, IsTsar = isTsar };
            players.InsertOne(newPlayer);
            return newPlayer;
        }
    }
}
