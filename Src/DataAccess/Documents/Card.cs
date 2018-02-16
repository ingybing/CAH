using MongoDB.Bson;
using System;

namespace CardsAgainstHumanity.DataAccess.Documents
{
    public class Card
    {
        public ObjectId Id { get; set; }
        public ObjectId? PlayerHandId { get; set; }
        public DateTime? LastSeen { get; set; }
        public string Text { get; set; }
        public int Pick { get; set; }
        public CardType Type { get; set; }
        public bool Played { get; set; }
    }
}
