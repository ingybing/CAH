using CardsAgainstHumantiy.Api.DataContracts.Types;
using System.Collections.Generic;
using System.ServiceModel;
using System.ServiceModel.Web;

namespace CardsAgainstHumantiy.Api.DataContracts.Service
{
    // NOTE: You can use the "Rename" command on the "Refactor" menu to change the interface name "IService1" in both code and config file together.
    [ServiceContract]
    public interface IGameAPI
    {
        [OperationContract]
        [WebGet(ResponseFormat = WebMessageFormat.Json, UriTemplate = "player/{id}")]
        PlayerContract GetPlayer(string id);

        [OperationContract]
        [WebInvoke(Method = "PUT", BodyStyle = WebMessageBodyStyle.Wrapped, ResponseFormat = WebMessageFormat.Json, UriTemplate = "player/add/{name}")]
        PlayerContract AddPlayer(string name);

        [OperationContract]
        [WebGet(ResponseFormat = WebMessageFormat.Json, UriTemplate = "player/tsar")]
        PlayerContract GetTsar();

        [OperationContract]
        [WebGet(ResponseFormat = WebMessageFormat.Json, UriTemplate = "cards/black/get")]
        CardContract GetBlackCard();
        
        [OperationContract]
        [WebGet(ResponseFormat = WebMessageFormat.Json, UriTemplate = "cards/black/draw/{playerId}")]
        CardContract DrawBlackCard(string playerId);

        [OperationContract]
        [WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.Wrapped, RequestFormat = WebMessageFormat.Json, UriTemplate = "card/playCards")]
        void PlayCards(string playerId, string[] cardId);

        [OperationContract]
        [WebGet(ResponseFormat = WebMessageFormat.Json, UriTemplate = "cards/played")]
        IList<CardContract> GetPlayedCards();

        [OperationContract]
        [WebInvoke(Method = "POST", RequestFormat = WebMessageFormat.Json, ResponseFormat = WebMessageFormat.Json, UriTemplate = "cards/exchange")]
        IList<CardContract> ExchangeCards(string[] cardsId);

        [OperationContract]
        [WebGet(ResponseFormat = WebMessageFormat.Json, UriTemplate = "players/details")]
        IList<PlayerContract> GetPlayerDetails();

        [OperationContract]
        [WebGet(ResponseFormat = WebMessageFormat.Json, UriTemplate = "cards/white/{playerId}")]
        IList<CardContract> GetWhiteCards(string playerId);

        [OperationContract]
        [WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.Wrapped, RequestFormat = WebMessageFormat.Json, ResponseFormat = WebMessageFormat.Json, UriTemplate = "round/selectWinner")]
        void SelectWinner(string tsar, string winner);

        [OperationContract]
        [WebGet(ResponseFormat = WebMessageFormat.Json, UriTemplate = "game/end")]
        string EndGame();

        [OperationContract]
        [WebGet(ResponseFormat = WebMessageFormat.Json, UriTemplate = "round/isFinished")]
        bool IsRoundFinished();
    }
}
