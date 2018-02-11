using System;
using System.Runtime.Serialization;

namespace CardsAgainstHumantiy.Api.DataContracts.Types
{
    [DataContract]
    public class PlayerContract
    {
        [DataMember]
        public string Id { get; set; }

        [DataMember]
        public String Name { get; set; }

        [DataMember]
        public int Points { get; set; }

        [DataMember]
        public bool IsTsar { get; set; }
    }
}