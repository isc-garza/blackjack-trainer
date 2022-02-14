/// A Table is a container for Players.  Players sit at numbered positions, 1-indexed.
/// Position 1 is the farthest to the dealer's left and is dealt to first.  The number of seat may range
/// from 5 to 9.  The table also has properties for the rule variations of Blackjack:<br>
/// -Whether the dealer must hit on soft 17
/// -Surrender: Early (usually not in U.S.), Late, or None<br>
/// -Doubling: Any two cards, 9/10/11 only, or 10/11 only
/// -Max Hands Player May Split To
/// -Double After Split: Allowed or not
/// -Hit Split Aces: Allowed or not (usually not)
/// -Resplit Aces: Allowed or not.
Class Trainer.Table Extends %RegisteredObject
{

/// Set when the table is instantiated.  May range from 5 to 9.
Property NumberOfSeats As %Integer;

/// A simple 1-indexed array with a node for each seat at the table.
/// The value at each node is either an oref to a Player or the null string ("").
/// The value of the property itself is the number of players at the table.
Property Players [ MultiDimensional ];

/// The dealer isn't really a player, so don't make them one.  Just give them a hand.
Property DealersHand As Trainer.Hand;

/// Used when printing the table to determine if the dealers hole card should be shown or hidden
Property DealerShowingHoleCard As %Boolean [ InitialExpression = 0 ];

/// Whether the dealer must hit on soft 17
Property DealerHitsSoft17 As %Binary [ InitialExpression = 0 ];

/// Whether and what type of surrender is allowed (early, late, or none)
Property SurrenderAllowed As %String(VALUELIST = ",Early,Late,None") [ InitialExpression = "Late" ];

/// On what value hands doubling is allowed (any two cards, 9-10-11 only, or 10-11 only)
Property DoublingAllowed As %String(VALUELIST = ",Any,9-10-11 Only,10-11 Only") [ InitialExpression = "Any" ];

/// The maximum number of hands that may be split to by one seat.
Property MaxHandsPerSeat As %Integer [ InitialExpression = 4 ];

/// Whether a split hand may be doubled
Property DoubleAfterSplitAllowed As %Binary [ InitialExpression = 1 ];

/// Whether a split hand whose first card is an ace may be hit
Property HitSplitAcesAllowed As %Binary [ InitialExpression = 0 ];

/// Whether resplitting of aces is allowed
Property ResplittingAcesAllowed As %Binary [ InitialExpression = 1 ];

/// The shoe the game is played with.
Property Shoe As Trainer.Shoe;

/// How many human are currently at the table (and, consequently,
/// whether there are any human at the table.
Property HumansAtTable As %Binary [ InitialExpression = 0 ];

Method %OnNew(pNumberOfSeats As %Integer) As %Status
{
	if ((pNumberOfSeats<5)||(pNumberOfSeats>9)) { quit $$$ERROR("Number of seats must be between 5 and 9: "_pNumberOfSeats) }
	set ..NumberOfSeats = pNumberOfSeats
	for i=1:1:..NumberOfSeats {
		set ..Players(i) = ""
	}
	set ..Players = 0
	set ..DealersHand = ##class(Trainer.Hand).%New()
	set ..Shoe = ##class(Trainer.Shoe).%New()
	quit $$$OK
}

/// Adds a player to the table at a given postion.  If the position is already
/// filled, the given player takes the position of the existing player.  Also
/// pPosition must not be greater than the number of positions at the table.
Method AddPlayer(pPosition As %Integer, pPlayer As Trainer.Player) As %Status
{
	if ((pPosition<1)||(pPosition>..NumberOfSeats)) { quit $$$ERROR("Argument pPosition out of bounds, must be between 1 and "_..NumberOfSeats_": "_pPosition) }
	set ..Players(pPosition) = pPlayer
	set ..Players = ..Players+1
	if ('pPlayer.IsComputer) { set ..HumansAtTable = ..HumansAtTable + 1 }
	quit $$$OK
}

/// Removes the player from the table at the given position.  If not player is at
/// that position, this does nothing.
Method RemovePlayer(pPosition As %Integer) As %Status
{
	if ((pPosition<1)||(pPosition>..NumberOfSeats)) { quit $$$ERROR("Argument pPosition out of bounds, must be between 1 and "_..NumberOfSeats_": "_pPosition) }
	set tPlayer = ..Players(pPosition)
	if (tPlayer '= "") {
		set ..Players(pPosition) = ""
		set ..Players = ..Players-1
		if ('tPlayer.IsComputer) { set ..HumansAtTable = ..HumansAtTable - 1 }
	}
}

Method Print(pPlaying As %Binary = 1)
{
	//clear the terminal screen
	write #
	
	if ((..DealerShowingHoleCard)||(..DealersHand.Size<2)) { write ?30, "Dealer: "_..DealersHand.Cards }
	else { write ?30, "Dealer: "_$P(..DealersHand.Cards,",")_",<Down>" }
	write ?90, "HandsPlayed: "_%HandsDealt
	write !, ?90, "Count: "_%Count
	write !, ?90, "Decks Remaining: "_%DecksRemaining
	write !, ?90, "True Count: ", %Count/%DecksRemaining
	write !!
	//One row per possible hand, plus 1 for "Seat <#>"
	for tRowNum = 1:1:..MaxHandsPerSeat {
		for tPlayerNum=..NumberOfSeats:-1:1 {
			if (..Players(tPlayerNum) = "") {
				if (tRowNum = ..MaxHandsPerSeat) { write ?(..NumberOfSeats-tPlayerNum)*21, "<Empty>" }
			}
			else { 
				if (..Players(tPlayerNum).Hands.GetAt(tRowNum)'="") { 
					write ?(..NumberOfSeats-tPlayerNum)*21, ..Players(tPlayerNum).Hands.GetAt(tRowNum).Cards
					write ?((..NumberOfSeats-tPlayerNum)*21)+10, "$"_..Players(tPlayerNum).Hands.GetAt(tRowNum).Bet
					if (..Players(tPlayerNum).Hands.GetAt(tRowNum).Winnings'=0) { write " $"_..Players(tPlayerNum).Hands.GetAt(tRowNum).Winnings }
				}
			}
		}
		write !
	}
	for tPlayerNum=..NumberOfSeats:-1:1 { write ?(..NumberOfSeats-tPlayerNum)*21, "Seat "_tPlayerNum}
	write !!
	for tPlayerNum=..NumberOfSeats:-1:1 { 
		if (..Players(tPlayerNum)'="") { write ?(..NumberOfSeats-tPlayerNum)*21, "$"_..Players(tPlayerNum).Bankroll }
	}
	write !
	for tPlayerNum=..NumberOfSeats:-1:1 {
		if (..Players(tPlayerNum)'="") {
			if (..Players(tPlayerNum).IsComputer) { write ?(..NumberOfSeats-tPlayerNum)*21, "Computer" }
			else { write ?(..NumberOfSeats-tPlayerNum)*21, "Human" }
		} 
	}
	write !
	for tPlayerNum=..NumberOfSeats:-1:1 {
		if (..Players(tPlayerNum)'="") { write ?(..NumberOfSeats-tPlayerNum)*21, ..Players(tPlayerNum).Strategy }
	}
	if (pPlaying) {
		if ((..HumansAtTable)||(%Sim("HumanlessPauses") = 4)) { read !, "Any key to continue.", tdummy#1 }
	}
	quit
}

Method HasPlayerAtSeat(pSeatNum As %Integer) As %Boolean
{
	quit (..Players(pSeatNum) '= "")
}

/// Returns the dealer's up card (the first card in their hand)
Method DealersUpCard() As %String
{
	quit $P(..DealersHand.Cards, ",", 1)
}

/// Returns true if there are still players' hands being played at the table, false otherwise.
/// Hands (actually cards, hand objects stay) get removed immediately if they hit blackjack or if they bust.
Method HandsLeft() As %Boolean
{
	set tHandsLeft = 0
	for i=1:1:..NumberOfSeats
	{
		if (..HasPlayerAtSeat(i)) { set tPlayer = ..Players(i) }
		else { continue }
		set tHandNum = 0
		for {
			set tHandNum = tHandNum + 1
			set tHand = tPlayer.Hands.GetAt(tHandNum)
			//Out of hands - done with this player, go to next one
			if (tHand = "") { quit }
			//There is a hand, but no cards - it either busted or got blackjack
			elseif (tHand.Cards = "") { continue }
			//Otherwise this must be a hand with cards
			else { 
				set tHandsLeft = 1 
				quit
			}
		}
		//No need to check remaining players if we already know there's a hand.
		if (tHandsLeft = 1) { quit }
	}
	quit tHandsLeft
}

}

