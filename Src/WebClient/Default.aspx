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
                updateScoreboard(waitUntilAllPlayersJoin, isFromBrowserRefresh);
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
                    if (!isFromBrowserRefresh && self.playerDetails.IsTsar) {
                        drawBlackCard();
                    }
                    else {
                        getBlackCard();
                    }

                    getWhiteCards();
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

            function drawBlackCard()
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
                    })
                    .fail(function () {
                        $.notify("Failed to draws black card.", "error");
                    });
            }

            function getBlackCard()
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

                var data = { playerId : "" , cardId : [] };
                data.playerId = self.playerDetails.Id;
                data.cardId = self.selectedCards;

                $.ajax(
                {
                    url: "../CahAPI/GameApi.svc/card/playCards",
                    method: "POST",
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
                        Shitting on peoples laptop keyboard and then closing the lid.
                        <div class="cardOrder" id="whiteCard1Order"><div class="cardOrderNumber">1</div></div>
                    </div>
                    <div class="whiteCard" id="whiteCard2">
                        Shitting on peoples laptop keyboard and then closing the lid.
                        <div class="cardOrder" id="whiteCard2Order"><div class="cardOrderNumber">2</div></div>
                    </div>
                    <div class="whiteCard" id="whiteCard3">
                        Shitting on peoples laptop keyboard and then closing the lid.
                        <div class="cardOrder" id="whiteCard3Order"><div class="cardOrderNumber">3</div></div>
                    </div>
                    <div class="whiteCard" id="whiteCard4">
                        Shitting on peoples laptop keyboard and then closing the lid.
                        <div class="cardOrder" id="whiteCard4Order"><div class="cardOrderNumber">4</div></div>
                    </div>
                    <div class="whiteCard" id="whiteCard5">
                        Shitting on peoples laptop keyboard and then closing the lid.
                        <div class="cardOrder" id="whiteCard5Order"><div class="cardOrderNumber">5</div></div>
                    </div>
                    <div class="whiteCard" id="whiteCard6">
                        Shitting on peoples laptop keyboard and then closing the lid.
                        <div class="cardOrder" id="whiteCard6Order"><div class="cardOrderNumber">6</div></div>
                    </div>
                </div>
            </div>
            <div id="tsar">
                <h1>You are the Tsar this round.</h1>
            </div>
        </form>
    </body>
</html>
