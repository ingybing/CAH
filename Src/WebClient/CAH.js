var playerDetails;
var pick = 0;
var cardsPicked = 0;
var selectedCards = new Array();
var otherPlayers;
var alreadyGotWhiteCardsThisRound = false;

$(document).ready(function () {
    console.info("Initialising...");

    $("#blackCard").hide();
    $("#whiteCards").hide();
    $("#addNewPlayer").hide();
    $("#scoreboard").hide();
    $("#tsar").hide();
    $("#submitCards").hide();

    $(".whiteCard").click(whiteCardClicked);

    $("body").show();

    wouldYouStartTheFansPlease();
});

function wouldYouStartTheFansPlease() {
    console.info("Entering wouldYouStartTheFansPlease");

    self.IsPlayerValid(function (player) {
        console.info("Entering IsPlayerValid callBack");
        if (player == null || player == "") {
            console.info("Doesn't look like it. Please join in.");

            // Allow new player registration.
            $("#playerSubmit").click(addNewPlayer);
            $("#addNewPlayer").show();
        }
        else {
            console.info("Welcome back " + player.Name + ".");
            self.setPlayerDetails(player, true);
        }
        console.info("Exiting IsPlayerValid callBack");
    });
    console.info("Exiting wouldYouStartTheFansPlease");
}

function IsPlayerValid(resultHandler) {
    console.info("Entering IsPlayerValid");

    var playerId = getCookie("playerId");
    if (playerId != null && playerId.length > 0) {
        console.info("Go value from cookie: " + playerId);
        $.ajax(
            {
                url: "../CahAPI/GameApi.svc/player/" + playerId,
                method: "GET",
            })
            .done(function (data) {
                resultHandler(data);
            })
            .fail(function (jqXHR, textStatus, errorThrown) {
                console.error("An error occurred calling api.");
                console.error(textStatus);
                console.error(errorThrown);
            });
    }
    else {
        resultHandler(null);
    }

    console.info("Exiting IsPlayerValid");
}

function disableButton(item) {
    console.info("Entering disableButton");

    item.removeClass("button").addClass("button-disabled");
    item.unbind();

    console.info("Exiting disableButton");
}

function enableButton(item, clickFunction) {
    console.info("Entering wouldYouStartTheFansPlease");

    item.removeClass("button-disabled").addClass("button");
    item.click(clickFunction);

    console.info("Exiting wouldYouStartTheFansPlease");
}

function addNewPlayer() {
    console.info("Entering addNewPlayer");

    var playerName = $("#playerName").val();
    console.info("Player name is: " + playerName);

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
        .fail(function (jqXHR, textStatus, errorThrown) {
            console.error("An error occurred calling api.");
            console.error(textStatus);
            console.error(errorThrown);

            updateScoreboard(false);
            enableButton(playerSubmitButton, addNewPlayer);
        });

    console.info("Exiting addNewPlayer");
}

function setPlayerDetails(data, isFromBrowserRefresh) {
    console.info("Entering setPlayerDetails");

    self.playerDetails = data;
    setCookie("playerId", self.playerDetails.Id, 1);

    $("#addNewPlayer").hide();
    $("#submitCards").show();

    if (!isFromBrowserRefresh && self.playerDetails.IsTsar) {
        drawBlackCard(function () {
            console.info("Entering SetPlayerDetails::DrawBlackCard::Callback");
            updateScoreboard(waitUntilAllPlayersJoin, isFromBrowserRefresh);
            console.info("Exiting SetPlayerDetails::DrawBlackCard::Callback");
        });
    }
    else {
        getBlackCard(function () {
            console.info("Entering SetPlayerDetails::GetBlackCard::Callback");
            updateScoreboard(waitUntilAllPlayersJoin, isFromBrowserRefresh);
            console.info("Exiting SetPlayerDetails::GetBlackCard::Callback");
        });
    }

    console.info("Exiting setPlayerDetails");
}

function waitUntilAllPlayersJoin(players, isFromBrowserRefresh) {
    console.info("Entering waitUntilAllPlayersJoin");

    if (players.length < 3) {
        var playersRequired = 3 - players.length;
        var playerLabel = "player";
        if (playersRequired > 1) {
            playerLabel = playerLabel + "s";
        }

        console.info("Waiting for " + playersRequired + " other " + playerLabel + " to join.");
        setTimeout(function () { updateScoreboard(waitUntilAllPlayersJoin, isFromBrowserRefresh); }, 5000);
    }
    else {
        waitForAllPlayedCards();
    }

    console.info("Exiting waitUntilAllPlayersJoin");
}

function updateScoreboard(completeDelegate, isFromBrowserRefresh) {
    console.info("Entering updateScoreboard");
    $.ajax(
        {
            url: "../CahAPI/GameApi.svc/players/details",
            method: "GET",
        })
        .done(function (data) {
            self.otherPlayers = data;
            var scoreboard = $("#scoreboard");
            var html = "<u>Scoreboard:</u><br/><br/>";
            for (i in data) {
                var player = data[i];
                html = html + player.Points + " - " + player.Name + "<br/>";
            }
            scoreboard.html(html);
            scoreboard.show();
            completeDelegate(data, isFromBrowserRefresh)
        })
        .fail(function (jqXHR, textStatus, errorThrown) {
            console.error("An error occurred calling api.");
            console.error(textStatus);
            console.error(errorThrown);
        });

    console.info("Exiting updateScoreboard");
}

function drawBlackCard(completedDelegate) {
    console.info("Entering drawBlackCard");

    $.ajax(
        {
            url: "../CahAPI/GameApi.svc/cards/black/draw/" + self.playerDetails.Id,
            method: "GET",
        })
        .done(function (data) {
            console.info("Got a black card");
            setBlackCard(data);
            if (completedDelegate != undefined) {
                completedDelegate();
            }
        })
        .fail(function (jqXHR, textStatus, errorThrown) {
            console.error("An error occurred calling api.");
            console.error(textStatus);
            console.error(errorThrown);
        });

    console.info("Exiting drawBlackCard");
}

function getBlackCard(completedDelegate) {
    console.info("Entering getBlackCard");

    $.ajax(
        {
            url: "../CahAPI/GameApi.svc/cards/black/get",
            method: "GET",
        })
        .done(function (data) {
            console.info("Got a black card");
            setBlackCard(data);

            if (completedDelegate != undefined) {
                completedDelegate();
            }
        })
        .fail(function (jqXHR, textStatus, errorThrown) {
            console.error("An error occurred calling api.");
            console.error(textStatus);
            console.error(errorThrown);
        });

    console.info("Exiting getBlackCard");
}

function setBlackCard(data) {
    console.info("Entering setBlackCard");

    var blackCard = $("#blackCard");
    blackCard.html(data.Text);
    blackCard.show();

    self.pick = data.Pick;

    console.info("Exiting setBlackCard");
}

function getWhiteCards() {
    console.info("Entering getWhiteCards");

    if (self.playerDetails.IsTsar) {
        $("#tsar").show();
    }
    else {
        $("#tsar").hide();
        console.info("Getting white cards.");
        $.ajax(
            {
                url: "../CahAPI/GameApi.svc/cards/white/" + self.playerDetails.Id,
                method: "GET",
            })
            .done(function (data) {
                console.info("Got a white cards");

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
            .fail(function (jqXHR, textStatus, errorThrown) {
                console.error("An error occurred calling api.");
                console.error(textStatus);
                console.error(errorThrown);
            });
    }

    console.info("Exiting getWhiteCards");
}

function whiteCardClicked(event) {
    console.info("Entering whiteCardClicked");
    var whiteCard = event.target;
    var id = whiteCard.id;
    var tag = whiteCard.getAttribute("tag");
    var orderIndex = $.inArray(tag, self.selectedCards);
    if (orderIndex == -1) {
        // card isn't in the selected cards.
        var order = (self.cardsPicked + 1);
        if (order <= self.pick) {
            self.selectedCards[self.cardsPicked] = tag;
            whiteCard.innerHTML = whiteCard.innerHTML + "<div class=\"cardOrder\"><div class=\"cardOrderNumber\">" + order + "</div></div>";
            self.cardsPicked = order;
        }
    }
    else {
        // card is in the selected cards list so remove it and re-order.
        $(event.target).find("div").remove(); //remove bubble.
        var i = orderIndex;
        while ((i + 1) < self.selectedCards.length) {
            self.selectedCards[i] = self.selectedCards[i + 1];
            i++;
        }
        self.cardsPicked--;
        var numberOfSlotsToSplice = self.selectedCards.length - self.cardsPicked;
        self.selectedCards.splice(self.cardsPicked, numberOfSlotsToSplice);
        for (var i = 0; i < self.selectedCards.length; i++) {
            var tagIdToFind = self.selectedCards[i];
            var selector = ".whiteCard[tag=" + tagIdToFind + "]";
            var whiteCardMatchingTag = $(selector).find("div").find("div").html(i + 1);
        }
    }

    var submitCardsButton = $("#submitCards");
    if (self.selectedCards.length == self.pick) {
        enableButton(submitCardsButton, submitCards);
    }
    else {
        disableButton(submitCardsButton);
    }

    console.info("Exiting whiteCardClicked");
}

function submitCards() {
    console.info("Entering submitCards");
    var submitCardsButton = $("#submitCards");
    disableButton(submitCardsButton);

    var data = { PlayerId: "", CardId: [] };
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
        self.cardsPicked = 0;
        self.selectedCards = new Array();

        disableButton(submitCardsButton);
        console.info("Submitted Cards");
        console.info("Waiting for Tsar.");

        $("#whiteCards").show();
    })
    .fail(function (jqXHR, textStatus, errorThrown) {
        console.error("An error occurred calling api.");
        console.error(textStatus);
        console.error(errorThrown);

        enableButton(submitCardsButton, submitCards);
    });

    console.info("Exiting submitCards");
}

function waitForAllPlayedCards() {
    console.info("Entering waitForAllPlayedCards");
    getPlayedCards(function (cards) {
        var uniquePlayersHands = new Array();
        var uniqueIndex = 0;
        for (var i in cards) {
            var card = cards[i];
            var playerId = card.PlayerHandId;
            if ($.inArray(playerId, uniquePlayersHands) == -1) {
                uniquePlayersHands[uniqueIndex] = playerId;
                uniqueIndex++;
            }
        }

        if (!self.alreadyGotWhiteCardsThisRound && $.inArray(self.playerDetails.Id, uniquePlayersHands) == -1) {
            getWhiteCards();
        }

        if ($.inArray(self.playerDetails.Id, uniquePlayersHands) != -1) {
            $("#whiteCards").hide();
        }

        renderPlayedCards(cards);

        if (uniquePlayersHands.length != (self.otherPlayers.length - 1)) {
            console.info("Waiting for other players to play their hands.");
            setTimeout(waitForAllPlayedCards, 1000);
        }
        else {
            console.info("All players have played their hands");
            if (!self.playerDetails.IsTsar) {
                waitWhileRoundIsFinished();
            }
        }
    });


    console.info("Exiting waitForAllPlayedCards");
}

function getPlayedCards(successDelegate) {
    console.info("Entering getPlayedCards");

    $.ajax(
    {
        url: "../CahAPI/GameApi.svc/cards/played",
        method: "GET"
    })
    .done(function (data) {
        console.info("Done Fetching Played Cards");
        successDelegate(data);
    })
    .fail(function (jqXHR, textStatus, errorThrown) {
        console.error("An error occurred calling api.");
        console.error(textStatus);
        console.error(errorThrown);
    });

    console.info("Exiting getPlayedCards");
}

function getPlayerById(id) {
    console.info("Entering getPlayerById");
    for (var i in self.otherPlayers) {
        var player = self.otherPlayers[i];
        if (player.Id == id) {

            console.info("Exiting getPlayerById");
            return player;
        }
    }

    console.info("Exiting getPlayerById");
    return undefined;
}

function renderPlayedCards(cards) {
    console.info("Entering renderPlayedCards");
    var playedCardsDiv = $("#playedCards");
    playedCardsDiv.find("div").remove();

    var currentPlayer;
    var div;
    var whiteCardsContainer;
    for (var i in cards) {
        var card = cards[i];
        if (currentPlayer != card.PlayerHandId) {
            currentPlayer = card.PlayerHandId;
            if (div != undefined) {
                div.append(whiteCardsContainer);
                playedCardsDiv.append(div);
            }

            whiteCardsContainer = $("<div></div>").addClass("whiteCards");
            div = $("<div></div>").attr("id", currentPlayer);
        }

        var whiteCard = $("<div></div>").addClass("whiteCard").html(card.Text).attr("tag", card.Id);
        if (self.playerDetails.IsTsar) {
            whiteCard.click(selectWinner);
        }

        whiteCardsContainer.append(whiteCard);
    }

    if (div != undefined) {
        div.append(whiteCardsContainer);
        playedCardsDiv.append(div);
    }

    console.info("Exiting renderPlayedCards");
}

function selectWinner(event) {
    console.info("Entering selectWinner");
    drawBlackCard(function () {
        var data = { tsar: self.playerDetails.Id, winner: event.target.getAttribute("tag") };

        $.ajax(
        {
            url: "../CahAPI/GameApi.svc/round/selectWinner",
            method: "POST",
            contentType: "application/json; charset=UTF-8; charset-uf8",
            data: JSON.stringify(data),
        })
        .done(function (data) {
            console.info("Winner selected.");
            getTsar(function () { updateScoreboard(waitUntilAllPlayersJoin, false); });
        })
        .fail(function (jqXHR, textStatus, errorThrown) {
            console.error("An error occurred calling api.");
            console.error(textStatus);
            console.error(errorThrown);
        });
    });

    console.info("Exiting selectWinner");
}

function getTsar(completedDelegate) {
    console.info("Entering getTsar");
    $.ajax(
    {
        url: "../CahAPI/GameApi.svc/player/tsar",
        method: "GET",
    })
    .done(function (data) {
        console.info("Got Tsar.");
        self.playerDetails.IsTsar = data.Id == self.playerDetails.Id;
        if (completedDelegate != undefined) {
            completedDelegate();
        }
    })
    .fail(function (jqXHR, textStatus, errorThrown) {
        console.error("An error occurred calling api.");
        console.error(textStatus);
        console.error(errorThrown);
    });

    console.info("Exiting getTsar");
}


function waitWhileRoundIsFinished() {
    console.info("Entering waitWhileRoundIsFinished");
    $.ajax(
    {
        url: "../CahAPI/GameApi.svc/round/isFinished",
        method: "GET",
    })
    .done(function (isFinished) {
        if (isFinished) {
            console.info("Rounds is finished, getting new cards.");
            self.alreadyGotWhiteCardsThisRound = false;
            getBlackCard();
            getTsar(function () { updateScoreboard(waitUntilAllPlayersJoin, false); });
        }
        else {
            setTimeout(waitWhileRoundIsFinished, 2000);
        }
    })
    .fail(function (jqXHR, textStatus, errorThrown) {
        console.error("An error occurred calling api.");
        console.error(textStatus);
        console.error(errorThrown);
    });

    console.info("Exiting waitWhileRoundIsFinished");
}