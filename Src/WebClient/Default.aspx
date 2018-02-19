<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
    <head runat="server">
        <title>Cards Against Humanity - Web Client</title>
	    <meta charset="utf-8" />
        <link href="CAH.css" rel="stylesheet" />
        <script src="jquery-3.3.1.min.js"></script>
        <script src="Cookie.js"></script>
        <script src="CAH.min.js"></script>
    </head>
    <body>
        <form id="form1" runat="server">
            <h1>Cards Against Humanity.</h1>
            <div class="centered">
                <div class="button-disabled" id="submitCards">Submit Cards</div>
                <!--<div class="button-disabled">End Game</div>-->
            </div>
            <div class="centered">
                <div class="scoreboard" id="scoreboard">
                    <u>Scoreboard:</u><br />
                </div>
                <div class="panel" id="addNewPlayer">
                    Name: <input id="playerName" type="text" /><br /><br />
                    <div class="button" id="playerSubmit">Join Game</div>
                </div>
                <div class="blackCard" id="blackCard">
                    Blackcard __________
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
