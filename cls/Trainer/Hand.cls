Class Trainer.Hand Extends %RegisteredObject
{

/// A comma-delimited list of the cards in a hand in the order they were dealt
Property Cards As %String;

/// The number of cards in the hand.
Property Size As %Integer [ InitialExpression = 0, SqlComputeCode = { set {Size} = $SELECT({Cards}="":0, 1:$LENGTH({Cards}, ",")) }, SqlComputed, SqlComputeOnChange = Cards ];

/// The simplified hand, used for lookups in strategy tables.<br>
/// If the hand is a pair, SimplifiedHand is "[value],[value]".<br>
/// If the hand contains an ace, SimplifiedHand is "A,[value of other cards]" unless it is a hard ace or a pair of aces.<br>
/// Otherwise, SimplifiedHand is the numeric value of the hand.
Property SimplifiedHand As %String [ SqlComputeCode = { set {SimplifiedHand} = ..SimplifyHand({Cards}) }, SqlComputed, SqlComputeOnChange = Cards ];

/// The numerical value of the hand.  Aces are counted as 11 unless doing so would cause the hand to bust.
Property Value As %Integer [ SqlComputeCode = { set {Value} = ..EvaluateHand({Cards}) }, SqlComputed, SqlComputeOnChange = Cards ];

/// Whether this hand was created by splitting another hand.  Needed if the first two cards are A,10, 
/// because a player cannot get blackjack on a split hand.
Property WasSplit As %Boolean [ InitialExpression = 0 ];

/// The amount that is currently bet on this hand.
Property Bet As %Double;

/// The winnings currently paid out to this hand.  Used when printing the table.
Property Winnings As %Double [ InitialExpression = 0 ];

/// Takes a comma-delimited list of cards in a hand and returns that hand "simplified".<br>
/// Ex: If the hand is a pair, it will return "[value],[value]".<br>
/// If the hand contains an ace, this will return "A,[value of other cards]" unless it is a hard ace or a pair of aces.<br>
/// Otherwise, this will return the numeric value of the hand.
ClassMethod SimplifyHand(pHand As %String) As %String
{
	//First check if we have a pair
	if (($LENGTH(pHand, ",") = 2) && ($PIECE(pHand, ",", 1) = $PIECE(pHand, ",", 2)))
	{
		//If so, just return the hand back, but not before converting face cards to 10's
		if (($EXTRACT(pHand) = "J")||($EXTRACT(pHand) = "Q")||($EXTRACT(pHand) = "K"))
		{
			quit "10,10"
		}
		else { quit pHand }
	}
	//Next check if the hand contains an ace
	if (pHand [ "A")
	{
		//Evaluate the rest of the hand, converting the other aces to 1's
		//position of comma following first ace
		set tPos = $FIND(pHand, "A")
		//extract ace + comma
		set $EXTRACT(pHand, tPos - 1, tPos) = ""
		set pHand = $TRANSLATE(pHand, "A", 1)
		set tHandValue = ..EvaluateHand(pHand)
		//if ace is soft (value of rest of hand < 10) return hand w/ ace
		if (tHandValue < 10)
		{
			quit "A,"_tHandValue
		}
		//else if the rest of the hand = 10, return 21
		elseif (tHandValue = 10) {
			quit 21
		}
		//this is a wierd case.  I think the hand would have to be A,A,10 for this to happen,
		//but aces should always be split, so this shouldn't happen even though it technically could...
		//whatever, just covering my bases.
		elseif (tHandValue = 21) {
			quit 12
		}
		//else just return value of hand
		else
		{
			quit tHandValue + 1
		}
	}
	//Finally, not a pair, no aces, just return the hand value
	quit ..EvaluateHand(pHand)
}

/// Takes a comma-delmited list of cards in a hand (ex: "A,2,3") and returns that hand's numeric value.
/// An ace will be counted as 11 unless doing so would cause the hand to bust.
ClassMethod EvaluateHand(pHand As %String) As %Integer
{
	set tHandValue = 0
	for tI=1:1:$LENGTH(pHand, ",")
	{
		set tCard = $PIECE(pHand, ",", tI)
		set tCardValue = $CASE(tCard, "A":1, "J":10, "Q":10, "K":10, :tCard)
		set tHandValue = tHandValue + tCardValue
	}
	if ((pHand [ "A") && (tHandValue <= 11))
	{
		quit tHandValue + 10
	}
	else
	{
		quit tHandValue
	}
}

Method GetDealtCard(pCard As %String)
{
	if (..Size '= 0) { set ..Cards = ..Cards_"," }
	set ..Cards = ..Cards_pCard
}

Method IsBlackjack() As %Boolean
{
	quit ((..Value = 21)&&(..Size = 2)&&('..WasSplit))
}

/// TODO: Take into account whether split is an option depending on the number of hands already
///       split to and the table max.<br>
/// This returns a String corresponding to the list of possible
/// actions that the player can take in two different ways:<br>
/// <nbsp><nbsp><nbsp><nbsp> [comma-delimited list of abbreviations]^[comma-delimited list of full actions] <br>
/// The list of abbreviations starts and ends with commas.  The full actions do not.
/// The full actions are separated by spaces.  The abbreviations are not.  So if a player had 5,5,
/// this method would return:<br>
/// <nbsp><nbsp><nbsp><nbsp> ,H,S,D,P,U,Q,W^(H)it, (S)tand, (D)ouble, S(p)lit, S(u)rrender, (Q)uit, W to Debug
Method GetPossibleActions() As %String
{
	//hit is always an option unless this hand was split, first card was an ace, and hitting split aces is not allowed.
	if ('((..WasSplit)&&($P(..Cards,",")="A")&&('%Table.HitSplitAcesAllowed))) {
		set tAbbrev = ",H,", tFull = "(H)it"
	}
	//stand is always an option
	set tAbbrev = tAbbrev_"S,", tFull = tFull_", (S)tand"
	//others are only possible as first decision (hand size = 2)
	if (..Size = 2) {
		//Double is available unless:
		//-Doubling is only allowed on certain hard totals ([9, ]10, or 11) and the hand's value is not one of those,
		//-This hand was split and double after split is not allowed,
		//-Or this hand was split, first card is an ace, and hitting split aces is not allowed.
		if (((%Table.DoublingAllowed="9-10-11 Only")&&((..Value<9)||(..Value>11)))||
		    ((%Table.DoublingAllowed="10-11 Only")&&((..Value<10)||(..Value>11)))||
		    ((..WasSplit)&&('%Table.DoubleAfterSplitAllowed))||
		    ((..WasSplit)&&($E(..Cards)="A")&&('%Table.HitSplitAcesAllowed))
		   ) {}
		else { set tAbbrev = tAbbrev_"D,", tFull = tFull_" , (D)ouble" }
		//split available if the two cards are the same, unless hand is A,A and was already split
		//and resplitting aces is not allowed
		//TODO: implement restriction on max number of times hand may be split
		if (($P(..Cards, ",") = $P(..Cards, ",", 2))&&
		    ('((..WasSplit)&&(..Cards="A,A")&&('%Table.ResplittingAcesAllowed)))
		   ) {
			set tAbbrev = tAbbrev_"P,"
			set tFull = tFull_" , S(p)lit"
		}
		//Surrender is an option if late surrender is allowed.
		//TODO: implement early surrender. Won't be here, will be before dealer checks for blackjack
		if (%Table.SurrenderAllowed = "Late") {
			set tAbbrev = tAbbrev_"U,"
			set tFull = tFull_" , S(u)rrender"
		}
	}
	//meta actions
	set tAbbrev = tAbbrev_"Q,W,"
	set tFull = tFull_", (Q)uit, W to Debug"
	quit tAbbrev_"^"_tFull
}

/// Returns whether this hand is soft. 1 = soft, 0 = not soft (hard)
Method IsSoft() As %Boolean
{
	quit (..SimplifiedHand["A")
}

}

