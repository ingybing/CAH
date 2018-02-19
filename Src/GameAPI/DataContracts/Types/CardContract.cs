using System.Runtime.Serialization;

namespace CardsAgainstHumantiy.Api.DataContracts.Types
{
    [DataContract]
    public class CardContract
    {
        [DataMember]
        public string Id { get; set; }

        [DataMember]
        public string Text { get; set; }

        [DataMember]
        public string PlayerHandId { get; set; }

        [DataMember]
        public int Pick { get; set; }

        [DataMember]
        public int Order { get; set; }
    }
}