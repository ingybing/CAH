using CardsAgainstHumantiy.Api.DataContracts.Service;
using CardsAgainstHumantiy.Api.DataContracts.Types;
using CardsAgainstHumanity.DataAccess;

using System;
using System.Collections.Generic;
using System.Linq;
using MongoDB.Bson;
using System.ServiceModel.Activation;

namespace CardsAgainstHumantiy.Api
{
    [AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
    public class GameAPI : IGameAPI
    {
        private Storage storage;

        public GameAPI()
        {
            this.storage = new Storage();
        }

        public PlayerContract AddPlayer(string name)
        {
            var player = this.storage.AddPlayer(name);
            return new PlayerContract { Id = player.Id.ToString(), Name = player.Name, Points = player.Points, IsTsar = player.IsTsar };
        }

        public String EndGame()
        {
            var winners = this.storage.GetWinner();

            var names = string.Join(" & ", winners.Select(x => x.Name));
            var result = winners.Count > 1 ? string.Format("{0} are the winners with {1} points!", names, winners.First().Points) : string.Format("{0} is the winner with {1} points!", names, winners.First().Points);

            return result;
        }

        public IList<CardContract> ExchangeCards(string[] cardsId)
        {
            var newCards = this.storage.ExchangeCards(cardsId.Select(x => new ObjectId(x)).ToList());
            return newCards.Select(x => new CardContract { Id = x.Id.ToString(), Text = x.Text }).ToList();
        }

        public CardContract DrawBlackCard(string playerId)
        {
            var card = storage.DrawBlackCard(new ObjectId(playerId));
            return new CardContract { Id = card.Id.ToString(),  Text = card.Text, Pick = card.Pick };
        }

        public CardContract GetBlackCard()
        {
            var card = storage.GetBlackCard();
            if (card != null)
            {
                return new CardContract { Id = card.Id.ToString(), Text = card.Text, Pick = card.Pick };
            }
            return null;
        }

        public IList<CardContract> GetWhiteCards(string playerId)
        {
            var cards = storage.GetWhiteCards(new ObjectId(playerId));
            var hand = cards.Select(x => new CardContract { Id = x.Id.ToString(), Text = x.Text }).ToList();
            return hand;
        }

        public IList<CardContract> GetPlayedCards()
        {
            var cards = this.storage.GetPlayedCards();
            return cards.Select(x => new CardContract { Id = x.Id.ToString(), Text = x.Text, PlayerHandId = x.PlayerHandId.ToString() }).ToList();
        }

        public IList<PlayerContract> GetPlayerDetails()
        {
            var players = this.storage.GetPlayers().OrderByDescending(x => x.Points).ThenBy(x => x.Name);
            return players.Select(x => new PlayerContract { Id = x.Id.ToString(), Name = x.Name, Points = x.Points, IsTsar = x.IsTsar}).ToList();
        }

        public PlayerContract GetPlayer(string id)
        {
            var player = this.storage.GetPlayer(new ObjectId(id));
            if(player != null)
            {
                return new PlayerContract { Id = player.Id.ToString(), Name = player.Name, Points = player.Points, IsTsar = player.IsTsar };
            }
            return null;
        }

        public void PlayCards(string playerId, string[] cards)
        {
            this.storage.PlayCard(new ObjectId(playerId), cards.Select(x => new ObjectId(x)).ToList());
        }

        public void SelectWinner(string tsar, string cardId)
        {
            this.storage.SelectWinner(new ObjectId(tsar), new ObjectId(cardId));
        }

        public PlayerContract GetTsar()
        {
            var tsar = this.storage.GetTsar();
            return new PlayerContract { Id = tsar.Id.ToString(), Name = tsar.Name, Points = tsar.Points, IsTsar = tsar.IsTsar };
        }

        public bool IsRoundFinished()
        {
            return this.storage.IsRoundFinished();
        }
    }
}
