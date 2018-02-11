using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace CardsAgainstHumanity.DataAccess.Documents
{
    public class Player
    {
        public ObjectId Id { get; set; }
        public string Name { get; set; }
        public int Points { get; set; }
        public int TsarSequence { get; set; }
        public bool IsTsar { get; set; }
    }
}
