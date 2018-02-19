<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
    <head runat="server">
        <title>Cards Against Humanity - Web Client</title>
	    <meta charset="utf-8" />
        <link href="CAH.css" rel="stylesheet" />
        <script src="jquery-3.3.1.min.js"></script>
        <script src="notify.min.js"></script>
        <script src="Cookie.js"></script>
        <script>

            var playerDetails;
            var pick = 0;
            var cardsPicked = 0;
            var selectedCards = new Array();
            var otherPlayers;
            var alreadyGotWhiteCardsThisRound = false;

            $(document).ready(function ()
            {
                $.notify("Initialising...", "info");
                $("#blackCard").hide();
                $("#whiteCards").hide();
                $("#addNewPlayer").hide();
                $("#scoreboard").hide();
                $("#tsar").hide();

                $(".whiteCard").click(whiteCardClicked);

                $("body").show();

                wouldYouStartTheFansPlease();
            });

            function wouldYouStartTheFansPlease()
            {
                this.IsPlayerValid(function (player) {
                    if (player == null || player == "")
                    {
                        $.notify("Doesn't look like it. Please join in.", "info");

                        // Allow new player registration.
                        $("#playerSubmit").click(addNewPlayer);
                        $("#addNewPlayer").show();
                    }
                    else
                    {
                        $.notify("Welcome back " + player.Name + ".", "success");
                        self.setPlayerDetails(player, true);
                    }
                });
            }

            function IsPlayerValid(resultHandler)
            {
                $.notify("Checking if you've joined a game...", "info");
                var playerId = getCookie("playerId");
                if (playerId != null && playerId.length > 0)
                {
                    $.ajax(
                        {
                            url: "../CahAPI/GameApi.svc/player/" + playerId,
                            method: "GET",
                        })
                        .done(function (data) {
                            resultHandler(data);
                        })
                        .fail(function () {
                            $.notify("Bumflakes, something went wrong checking if you've played before.", "error");
                            alert("Failed to check player id.");
                        });
                }
                else
                {
                    resultHandler(null);
                }
            }

            function disableButton(item)
            {
                console.log("changing class to button-disabled");
                item.removeClass("button").addClass("button-disabled");
                console.log("performing unbind");
                item.unbind();
            }

            function enableButton(item, clickFunction)
            {
                console.log("changing class to button-disabled");
                item.removeClass("button-disabled").addClass("button");

                console.log("performing click bind");
                item.click(clickFunction);
            }

            function addNewPlayer()
            {
                var playerName = $("#playerName").val();
                console.log("Player name is: " + playerName);

                var playerSubmitButton = $("#playerSubmit");
                disableButton(playerSubmitButton);

                $.ajax(
                    {
                        url: "../CahAPI/GameApi.svc/player/add/" + playerName,
                        method: "PUT",
                    })
                    .done(function (data) {
                        setPlayerDetails(data.AddPlayerResult, false);
                    })
                    .fail(function () {
                        $.notify("Failed to join, has your name already been taken?");
                        updateScoreboard(false);
                        enableButton(playerSubmitButton, addNewPlayer);
                    });
            }

            function setPlayerDetails(data, isFromBrowserRefresh)
            {
                self.playerDetails = data;
                setCookie("playerId", self.playerDetails.Id, 1);

                $("#addNewPlayer").hide();

                if (!isFromBrowserRefresh && self.playerDetails.IsTsar)
                {
                    drawBlackCard(function () { updateScoreboard(waitUntilAllPlayersJoin, isFromBrowserRefresh); });
                }
                else
                {
                    getBlackCard(function () { updateScoreboard(waitUntilAllPlayersJoin, isFromBrowserRefresh); });
                }
            }

            function waitUntilAllPlayersJoin(players, isFromBrowserRefresh)
            {
                if(players.length < 3)
                {
                    var playersRequired = 3 - players.length;
                    var playerLabel = "player";
                    if (playersRequired > 1)
                    {
                        playerLabel = playerLabel + "s";
                    }

                    $.notify("Waiting for " + playersRequired + " other " + playerLabel + " to join.", "info");
                    setTimeout(function () { updateScoreboard(waitUntilAllPlayersJoin, isFromBrowserRefresh); }, 5000);
                }
                else
                {
                    waitForAllPlayedCards();
                }
            }

            function updateScoreboard(completeDelegate, isFromBrowserRefresh)
            {
                $.ajax(
                    {
                        url: "../CahAPI/GameApi.svc/players/details",
                        method: "GET",
                    })
                    .done(function (data) {
                        self.otherPlayers = data;
                        var scoreboard = $("#scoreboard");
                        var html = "<u>Scoreboard:</u><br/><br/>";
                        for(i in data)
                        {
                            var player = data[i];
                            html = html + player.Points + " - " + player.Name + "<br/>";
                        }
                        scoreboard.html(html);
                        scoreboard.show();
                        completeDelegate(data, isFromBrowserRefresh)
                    })
                    .fail(function () {
                        $.notify("Failed to update scoreboard.", "error");
                    });
            }

            function drawBlackCard(completedDelegate)
            {
                $.notify("Drawing black card.", "info")
                $.ajax(
                    {
                        url: "../CahAPI/GameApi.svc/cards/black/draw/" + self.playerDetails.Id,
                        method: "GET",
                    })
                    .done(function (data) {
                        $.notify("Got a black card", "success");
                        setBlackCard(data);
                        if(completedDelegate != undefined)
                        {
                            completedDelegate();
                        }
                    })
                    .fail(function () {
                        $.notify("Failed to draws black card.", "error");
                    });
            }

            function getBlackCard(completedDelegate)
            {
                $.notify("Getting black card.", "info")
                $.ajax(
                    {
                        url: "../CahAPI/GameApi.svc/cards/black/get",
                        method: "GET",
                    })
                    .done(function (data) {
                        $.notify("Got a black card", "success");
                        setBlackCard(data);
                        if (completedDelegate != undefined)
                        {
                            completedDelegate();
                        }
                    })
                    .fail(function () {
                        $.notify("Failed to get black card.", "error");
                    });
            }

            function setBlackCard(data)
            {
                var blackCard = $("#blackCard");
                blackCard.html(data.Text);
                blackCard.show();

                self.pick = data.Pick;
            }

            function getWhiteCards()
            {
                if (self.playerDetails.IsTsar) {
                    $("#tsar").show();
                }
                else {
                    $("#tsar").hide();
                    $.notify("Getting white cards.", "info")
                    $.ajax(
                        {
                            url: "../CahAPI/GameApi.svc/cards/white/" + self.playerDetails.Id,
                            method: "GET",
                        })
                        .done(function (data) {
                            $.notify("Got a white cards", "success");

                            self.alreadyGotWhiteCardsThisRound = true;

                            for (i in data) {
                                var currentIndex = parseInt(i);
                                var selector = "#whiteCard" + (currentIndex + 1);
                                var whiteCard = $(selector);

                                var card = data[currentIndex];
                                whiteCard.html(card.Text);
                                whiteCard.attr("tag", card.Id);
                            }

                            $("#whiteCards").show();
                        })
                        .fail(function () {
                            $.notify("Failed to get white cards.", "error");
                        });
                }
            }

            function whiteCardClicked(event)
            {
                var whiteCard = event.target;
                var id = whiteCard.id;
                var tag = whiteCard.getAttribute("tag");
                var orderIndex = $.inArray(tag, self.selectedCards);
                if (orderIndex == -1)
                {
                    // card isn't in the selected cards.
                    var order = (self.cardsPicked + 1);
                    if (order <= self.pick)
                    {
                        self.selectedCards[self.cardsPicked] = tag;
                        whiteCard.innerHTML = whiteCard.innerHTML + "<div class=\"cardOrder\"><div class=\"cardOrderNumber\">" + order + "</div></div>";
                        self.cardsPicked = order;
                    }
                }
                else
                {
                    // card is in the selected cards list so remove it and re-order.
                    $(event.target).find("div").remove(); //remove bubble.
                    var i = orderIndex;
                    while((i+1) < self.selectedCards.length)
                    {
                        self.selectedCards[i] = self.selectedCards[i + 1];
                        i++;
                    }
                    self.cardsPicked--;
                    var numberOfSlotsToSplice = self.selectedCards.length - self.cardsPicked;
                    self.selectedCards.splice(self.cardsPicked, numberOfSlotsToSplice);
                    for(var i = 0; i < self.selectedCards.length; i++)
                    {
                        var tagIdToFind = self.selectedCards[i];
                        var selector = ".whiteCard[tag=" + tagIdToFind + "]";
                        var whiteCardMatchingTag = $(selector).find("div").find("div").html(i+1);
                    }
                }

                var submitCardsButton = $("#submitCards");
                if (self.selectedCards.length == self.pick) {
                    enableButton(submitCardsButton, submitCards);
                }
                else {
                    disableButton(submitCardsButton);
                }
            }

            function submitCards()
            {
                var submitCardsButton = $("#submitCards");
                disableButton(submitCardsButton);

                var data = { PlayerId : "" , CardId : [] };
                data.playerId = self.playerDetails.Id;
                data.cardId = self.selectedCards;

                $.ajax(
                {
                    url: "../CahAPI/GameApi.svc/card/playCards",
                    method: "POST",
                    contentType: "application/json; charset=UTF-8; charset-uf8",
                    data: JSON.stringify(data)
                })
                .done(function (data) {
                    disableButton(submitCardsButton);
                    $.notify("Submitted Cards", "success");
                    $.notify("Waiting for Tsar.", "info");

                    $("#whiteCards").show();
                })
                .fail(function () {
                    $.notify("Failed to submit cards.", "error");
                    enableButton(submitCardsButton, submitCards);
                });
            }

            function waitForAllPlayedCards()
            {
                getPlayedCards(function (cards)
                {
                    var uniquePlayersHands = new Array();
                    var uniqueIndex = 0;
                    for(var i in cards)
                    {
                        var card = cards[i];
                        var playerId = card.PlayerHandId;
                        if($.inArray(playerId, uniquePlayersHands) == -1)
                        {
                            uniquePlayersHands[uniqueIndex] = playerId;
                            uniqueIndex++;
                        }
                    }

                    if (!self.alreadyGotWhiteCardsThisRound && $.inArray(self.playerDetails.Id, uniquePlayersHands) == -1)
                    {
                        getWhiteCards();
                    }
                    
                    if ($.inArray(self.playerDetails.Id, uniquePlayersHands) != -1)
                    {
                        $("#whiteCards").hide();
                    }

                    renderPlayedCards(cards);

                    if(uniquePlayersHands.length != (self.otherPlayers.length - 1))
                    {
                        $.notify("Waiting for other players to play their hands.", "info");
                        setTimeout(waitForAllPlayedCards, 10000);
                    }
                    else
                    {
                        $.notify("All players have played their hands", "info");
                        if(!self.playerDetails.isTsar)
                        {
                            waitWhileRoundIsFinished();
                        }
                    }
                });
            }

            function getPlayedCards(successDelegate)
            {
                $.notify("Fetching played cards.", "info");

                $.ajax(
                {
                    url: "../CahAPI/GameApi.svc/cards/played",
                    method: "GET"
                })
                .done(function (data)
                {
                    $.notify("Done Fetching Played Cards", "success");
                    successDelegate(data);
                })
                .fail(function ()
                {
                    $.notify("Error fetching played cards", "error");
                });
            }

            function getPlayerById(id)
            {
                for(var i in self.otherPlayers)
                {
                    var player = self.otherPlayers[i];
                    if(player.Id == id)
                    {
                        return player;
                    }
                }

                return undefined;
            }

            function renderPlayedCards(cards)
            {
                var playedCardsDiv = $("#playedCards");
                playedCardsDiv.find("div").remove();

                var currentPlayer;
                var div;
                var whiteCardsContainer;
                for(var i in cards)
                {
                    var card = cards[i];
                    if(currentPlayer != card.PlayerHandId)
                    {
                        currentPlayer = card.PlayerHandId;
                        if(div != undefined)
                        {
                            div.append(whiteCardsContainer);
                            playedCardsDiv.append(div);
                        }

                        whiteCardsContainer = $("<div></div>").addClass("whiteCards");
                        div = $("<div></div>").attr("id", currentPlayer);
                    }

                    var whiteCard = $("<div></div>").addClass("whiteCard").html(card.Text).attr("tag", card.Id);
                    if (self.playerDetails.IsTsar)
                    {
                        whiteCard.click(selectWinner);
                    }

                    whiteCardsContainer.append(whiteCard);
                }

                if (div != undefined)
                {
                    div.append(whiteCardsContainer);
                    playedCardsDiv.append(div);
                }
            }

            function selectWinner(event)
            {
                drawBlackCard(function ()
                {
                    var data = { tsar: self.playerDetails.Id, winner: event.target.getAttribute("tag") };

                    $.ajax(
                    {
                        url: "../CahAPI/GameApi.svc/round/selectWinner",
                        method: "POST",
                        contentType: "application/json; charset=UTF-8; charset-uf8",
                        data: JSON.stringify(data),
                    })
                    .done(function (data) {
                        $.notify("Winner selected.", "success");
                        getTsar(function () { updateScoreboard(waitUntilAllPlayersJoin, false); });
                    })
                    .fail(function () {
                        $.notify("Error selecting winner.", "error");
                    });
                });
            }

            function getTsar(completedDelegate)
            {
                $.notify("Updating TSAR", "info");
                $.ajax(
                {
                    url: "../CahAPI/GameApi.svc/player/tsar",
                    method: "GET",
                })
                .done(function (data) {
                    $.notify("Got Tsar.", "success");
                    self.playerDetails.IsTsar = data.Id == self.playerDetails.Id;
                    if (completedDelegate != undefined)
                    {
                        completedDelegate();
                    }
                })
                .fail(function () {
                    $.notify("Error getting Tsar.", "error");
                });
            }


            function waitWhileRoundIsFinished() {
                $.notify("Checking round is finished.", "info");
                $.ajax(
                {
                    url: "../CahAPI/GameApi.svc/round/isFinished",
                    method: "GET",
                })
                .done(function (isFinished) {
                    if (isFinished)
                    {
                        $.notify("Rounds is finished, getting new cards.", "success");
                        self.alreadyGotWhiteCardsThisRound = false;
                        getTsar(function () { updateScoreboard(waitUntilAllPlayersJoin, false); });
                    }
                    else
                    {
                        setTimeout(waitWhileRoundIsFinished, 5000);
                    }
                })
                .fail(function () {
                    $.notify("Error checking if round is finished.", "error");
                });
            }
        </script>
    </head>
    <body>
        <form id="form1" runat="server">
            <h1>Cards Against Humanity.</h1>
            <div class="centered">
                <div class="button-disabled" id="submitCards">Submit Cards</div>
                <div class="button-disabled">End Game</div>
            </div>
            <div class="centered">
                <div class="scoreboard" id="scoreboard">
                    <u>Scoreboard:</u><br />
                    1. 0 - David<br />
                    2. 0 - Craig<br />
                    3. 0 - Kirsty<br />
                    4. 0 - Kim<br />
                </div>
                <div class="panel" id="addNewPlayer">
                    Name: <input id="playerName" type="text" /><br /><br />
                    <div class="button" id="playerSubmit">Join Game</div>
                </div>
                <div class="blackCard" id="blackCard">
                    Batmans Guilty Pleasure Is __________
                </div>
            </div>
            <div class="centered" id="whiteCards">
                <div class="whiteCards">
                    <div class="whiteCard" id="whiteCard1">
                        Card1
                    </div>
                    <div class="whiteCard" id="whiteCard2">
                        Card2
                    </div>
                    <div class="whiteCard" id="whiteCard3">
                        Card3
                    </div>
                    <div class="whiteCard" id="whiteCard4">
                        Card4
                    </div>
                    <div class="whiteCard" id="whiteCard5">
                        Card5
                    </div>
                    <div class="whiteCard" id="whiteCard6">
                        Card6
                    </div>
                </div>
            </div>
            <div id="tsar">
                <h1>You are the Tsar this round.</h1>
            </div>
            <div id="playedCards"></div>
        </form>
    </body>
</html>
