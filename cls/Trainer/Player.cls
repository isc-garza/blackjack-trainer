/// The base Player class is a human player.  Classes that extend this are computer
/// players playing different strategies.
/// TODO: Have GetCorrectAction get the correct action based on Strategy, not basic strategy all the time.
/// TODO: Also implement a mechanism that checks bets if a counting strategy is selected.
/// TODO: Computer players and GetCorrectAction need to look at table rules to see if certain actions are allowed
///      Ex: hitting split aces
Class Trainer.Player Extends %RegisteredObject
{

Parameter STRATEGY;

/// A player can have more than one hand (from splitting)
Property Hands As list Of Trainer.Hand;

/// TODO: Implement computer players
Property IsComputer As %Boolean [ InitialExpression = 0 ];

/// TODO: Implement different strategies for computer players (basic strategy, different types of counting, etc.)
Property Strategy As %String [ InitialExpression = {..#STRATEGY} ];

/// Amount of money the player has at the table.  Doesn't include what is currently bet.
Property Bankroll As %Double;

Property UnitBet As %Double;

Method GetAction(pDealersCard As %String, pHand As Trainer.Hand) As %String
{
	set tAction = ""
	set tPossibleActions = pHand.GetPossibleActions()
	//first piece is the comma-delimited list of abbreviations
	while $P(tPossibleActions,"^")'[(","_tAction_",") { 
		write !, "Action? ["_$P(tPossibleActions,"^",2)_"]"
		read tAction#1
		set tAction = $ZCVT(tAction, "U")
	}
	if ((tAction = "Q")||(tAction = "W")) { quit tAction }
	
	//Evaluate correct action
	set tCorrectAction = ..GetCorrectAction(pDealersCard, pHand)
	if (tAction = tCorrectAction) { 
		write !, "Correct!"
		set %CorrectMoves = %CorrectMoves + 1
	}
	else { 
		write !, "Wrong.  Correct action is: "_tCorrectAction
		set %IncorrectMoves = %IncorrectMoves + 1 
	}
	if ($DATA(%Explanation(pHand.SimplifiedHand))) { write " Reason: "_%Explanation(pHand.SimplifiedHand) }
	read dummy#1
	
	quit tAction
}

Method GetBet() As %Double
{
	if (..UnitBet > ..Bankroll) { quit ..Bankroll }
	else { quit ..UnitBet }
}

/// Given the dealer's up card and a player's hand, returns the correct move according to basic strategy.
ClassMethod GetCorrectAction(pDealersCard As %String, pPlayersHand As Trainer.Hand) As %String
{
	//Strategy matrix doesn't cover player's hand = hard 18-21 because correct move is always stand,
	//so implement that here.
	if (pPlayersHand.SimplifiedHand >= 18) { quit "S" }
	
	if ("JQK" [ pDealersCard) { set pDealersCard = 10 }
	set tCorrectAction = $E(%StrategyMatrix(pDealersCard), %HandIndex(pPlayersHand.SimplifiedHand)) 
	//Double and surrender can only be done only as the first move (hand size = 2 cards),
	//so check if we need to change those to something else.
	if (pPlayersHand.Size '= 2) {
		set tCorrectAction = $CASE(tCorrectAction, "D":"H", "O":"S", "U":"H", "R":"S", :tCorrectAction)
	}
	//If this is the first move, map O and R.
	else {
		set tCorrectAction = $CASE(tCorrectAction, "O":"D", "R":"U", :tCorrectAction)
	}
	
	quit tCorrectAction
}

ClassMethod GetStrategy() As %String
{
	quit ..#STRATEGY
}

}

