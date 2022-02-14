Class Trainer.HiLoCounterPlayer Extends Trainer.Player
{

Parameter STRATEGY = "HiLoCount";

Property IsComputer As %Boolean [ InitialExpression = 1 ];

/// Regular basic strategy - for now.
/// TODO: incorporate count into playing strategy.
Method GetAction(pDealersCard As %String, pHand As Trainer.Hand) As %String
{
	//Strategy matrix doesn't cover player's hand = hard 18-21 because correct move is always stand,
	//so implement that here.
	if (pHand.SimplifiedHand >= 18) { quit "S" }
	
	if ("JQK" [ pDealersCard) { set pDealersCard = 10 }
	set tCorrectAction = $E(%StrategyMatrix(pDealersCard), %HandIndex(pHand.SimplifiedHand)) 
	//Double and surrender can only be done only as the first move (hand size = 2 cards),
	//so check if we need to change those to something else.
	if (pHand.Size '= 2) {
		set tCorrectAction = $CASE(tCorrectAction, "D":"H", "O":"S", "U":"H", "R":"S", :tCorrectAction)
	}
	//If this is the first move, map O and R.
	else {
		set tCorrectAction = $CASE(tCorrectAction, "O":"D", "R":"U", :tCorrectAction)
	}
	
	quit tCorrectAction
}

Method GetBet() As %Double
{
	set tTrueCount = %Count / %DecksRemaining
	if (tTrueCount > 1) { 
		set tBet = tTrueCount * ..UnitBet
		if (tBet#5 >= 2.5) { set tBet = tBet + (5 - (tBet#5)) }
		else { set tBet = tBet - (tBet#5) }
		if (tBet > ..Bankroll) { quit ..Bankroll }
		else { quit tBet }
	}
	else { 
		if (..UnitBet > ..Bankroll) { quit ..Bankroll }
		else { quit ..UnitBet }
	}
}

}

