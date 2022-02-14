Class Trainer.Main Extends %RegisteredObject
{

/// Pause between dealing cards
Parameter PAUSEBTWCARDS = 0;

ClassMethod Start()
{
	//Initialize strategy matrix
	do ..Init()
	set (%HandsDealt,%DealerWins,%PlayerWinsNonBJ,%PlayerWinsBJ,%Pushes,%Surrenders,%CorrectMoves,%IncorrectMoves) = 0
	// This parameter controls when the game pauses and asks the user to do something (usually just push any key)
	// before the game continues if there are no human players at the table. The value of this can be 1 through 4.
	// Meaning of each is documented in the variable:
	set %Sim("HumanlessPauses") = 2
	set %Sim("HumanlessPauses",1) = "Pause only when the player runs out of money."
	set %Sim("HumanlessPauses",2) = "Above + Pause when the shoe is shuffled."
	set %Sim("HumanlessPauses",3) = "Above + Pause when a hand is over."
	set %Sim("HumanlessPauses",4) = "Above + Pause for any table action."
	
	write !, "TODO: Implement counting into playing strategy."
	write !, "TODO: Initialize strategy matrix according to table rules."
	write !, "Remember to increase the number of columns in the Terminal window to 132."
	write !, "NOTE: Stats are tracked for _ALL_ human players. This will work for more than 1 but is really only meaningful for 1."
	set tNumSeats = "" while ((+tNumSeats<5)||(+tNumSeats>9)) {
		read !, "Number of seats? <5-9, Default=5> ", tNumSeats#1
		if (tNumSeats = "") { set tNumSeats = 5 }
	}
	#dim %Table as Trainer.Table
	set %Table = ##class(Trainer.Table).%New(tNumSeats)
	do ..MainMenu()
}

ClassMethod MainMenu()
{
	for {
		do %Table.Print(0)
		write !!
		set tChoice = ""
		write !, "Main Menu:"
		write !, "1. PLAY!"
		write !, "2. Add/Edit/Remove Player"
		write !, "3. Review/Edit Table Rules"
		write !, "4. Review/Edit Simulation Parameters"
		write !, "5. Quit"
		read !,">>", tChoice#1
		
		if (tChoice = 1) {
			if (%Table.Players = 0) { 
				read !, "Add some players to the table first. Press any key to continue.", tDummy#1 
				continue 
			}
			do ..Game()
		}
		elseif (tChoice = 2) {
			do ..EditPlayer()
		}
		elseif (tChoice = 3) {
			do ..SetTableRules()
		}
		elseif (tChoice = 4) {
			do ..SetSimParams()
		}
		elseif (tChoice = 5) {
			quit
		}
	}
}

ClassMethod EditPlayer()
{
	do %Table.Print(0)
	write !!, "Choose a seat to add/edit/remove a player."
	set tSeatNum = ""
	while ((+tSeatNum<1)||(+tSeatNum>%Table.NumberOfSeats)) {
		read !,"Seat #: ", tSeatNum#1
	}
	
	//Add
	if ('%Table.HasPlayerAtSeat(tSeatNum)) {
		for {
			read !, "Is this player a computer or human? (c/h) ", tCompOrHuman#1
			if ((tCompOrHuman="c")||(tCompOrHuman="h")) { quit }
		}
		read !, "Starting bankroll? <Default=2500> ", tBankroll
		if (+tBankroll<=0) { set tBankroll = 2500 }
		read !, "Unit bet? <Default=25> ", tBet
		if (+tBet<=0) { set tBet = 25 }
		write !, "Playing what strategy? Options are:"
		kill tStrats
		do ..GetStrategies(.tStrats)
		set tI = "" for {
			set tI = $O(tStrats(tI)) quit:tI=""
			write !, tI_". "_$P(tStrats(tI),",",2)
		}
		set tStrat = ""
		while ((+tStrat<1)||(+tStrat>tStrats)) {
			read !, ">> ", tStrat#1
		}
		if (tCompOrHuman="h") { 
			set tPlayer = ##class(Trainer.Player).%New() 
			set tPlayer.Strategy = $P(tStrats(tStrat),",",2)
		}
		else { set tPlayer = $CLASSMETHOD($P(tStrats(tStrat),","), "%New") }
		set tPlayer.Bankroll = tBankroll
		set tPlayer.UnitBet = tBet
		set tSC = %Table.AddPlayer(tSeatNum, tPlayer)
		read !, "Player added. Press any key to continue.", tDummy#1
	}
	//Edit/Delete existing player
	else {
		set tPlayer = %Table.Players(tSeatNum)
		for {
			set tChoice = ""
			write !, "Choose or press Enter when done:"
			write !, "1. Change whether this player is computer or human (Currently "_$S(tPlayer.IsComputer:"computer", 1:"human")_")"
			write !, "2. Change bankroll (Currently "_tPlayer.Bankroll_")"
			write !, "3. Change unit bet (Currently "_tPlayer.UnitBet_")"
			write !, "4. Change strategy (Currently "_tPlayer.Strategy_") (TODO: implement this)"
			write !, "5. Remove player from table"
			while ((tChoice<1)||(tChoice>5)) {
				read !, ">>", tChoice#1
				if (tChoice = "") { quit }
			}
			if (tChoice = "") { quit }
			elseif (tChoice = 1) {
				set tChoice = "*"
				while ("ch"'[tChoice) {
					read !, "Enter 'c' or 'h' to specify computer or human, or Enter to leave unchanged: ", tChoice#1
				}
				if (tChoice '= "") { set tPlayer.IsComputer = (tChoice="c") }
			}
			elseif (tChoice = 2) {
				read !, "Enter new bankroll or press Enter to leave unchanged: ", tBankroll
				if (tBankroll '="" ) { set tPlayer.Bankroll = tBankroll }
			}
			elseif (tChoice = 3) {
				read !, "Enter a new unit bet or press Enter to leave unchanged: ", tBet
				if (tBet '= "") { set tPlayer.UnitBet = tBet }
			}
			elseif (tChoice = 4) {
				write !, "Not yet implemented."
				continue
				write !, "Choose a strategy or press Enter to leave unchanged:"
				kill tStrats
				do ..GetStrategies(.tStrats)
				set tI = "" for {
					set tI = $O(tStrats(tI)) quit:tI=""
					write !, tI_". "_$P(tStrats(tI),",",2)
				}
				set tStrat = ""
				while ((tStrat<1)||(tStrat>tStrats)) {
					read !, ">> ", tStrat#1
					if (tStrat = "") { quit }
				}
				if (tStrat '= "") { set tPlayer.Strategy = $P(tStrats(tStrat),",",2) }
			}
			elseif (tChoice = 5) {
				set tChoice = ""
				while (("yn"'[tChoice)||(tChoice="")) {
					read !, "Are you sure you want this player from the table? (y/n)", tChoice#1
				}
				if (tChoice = "y") {
					set tSC = %Table.RemovePlayer(tSeatNum)
					read !, "Player removed. Press any key to continue.", tDummy#1
					quit
				}
			}
			do %Table.Print(0)
			write !!
			write !, "Seat #: "_tSeatNum
		}
	}
}

ClassMethod GetStrategies(ByRef pStrats)
{
	set tRS = ##class(%ResultSet).%New()
	set tSC = tRS.Prepare("SELECT ID FROM %Dictionary.ClassDefinition WHERE Super = 'Trainer.Player'")
	set tSC = tRS.Execute()
	while (tRS.Next()) {
		set tClass = tRS.Data("ID")
		set tStrat = $CLASSMETHOD(tClass, "GetStrategy")
		set pStrats($I(pStrats)) = tClass_","_tStrat
	}
}

ClassMethod SetTableRules()
{
	write #
	for {
		set tChoice1 = "*"
		set tChoice2 = "*"
		write !, "Pick a table rule to set, or 'q' to go back to main menu."
		write !, "(1 is true, 0 is false)"
		write !, "1. Dealer hits on soft 17 (currently: "_%Table.DealerHitsSoft17_")"
		write !, "2. Whether and what type of surrender is allowed (currently: "_%Table.SurrenderAllowed_")"
		write !, "3. On what value hands doubling is allowed (currently: "_%Table.DoublingAllowed_")"
		write !, "4. The maximum number of hands that may be split to at one position (currently: "_%Table.MaxHandsPerSeat_")"
		write !, "5. Whether a split hand may be doubled (currently: "_%Table.DoubleAfterSplitAllowed_")"
		write !, "6. Whether a split hand whose first card is an ace may be hit (currently: "_%Table.HitSplitAcesAllowed_")"
		write !, "7. Whether re-splitting of aces is allowed (currently: "_%Table.ResplittingAcesAllowed_")"
		write !, "8. How many decks the game is played with (currently: "_%Table.Shoe.NumberOfDecks_")"
		write !
		read ">>", tChoice1#1
		if (tChoice1 = 1) {
			for {
				write !,!, "Select one or press Enter to leave choice as: "_%Table.DealerHitsSoft17
				write !, "0. Dealer stands on soft 17."
				write !, "1. Dealer hits on soft 17."
				write !
				read tChoice2#1
				if (tChoice2 = "") { quit}
				if ("01"[tChoice2) { set %Table.DealerHitsSoft17 = tChoice2 quit }
			}
		}
		if (tChoice1 = 2) {
			for {
				write !,!, "Select one or press Enter to leave choice as: "_%Table.SurrenderAllowed
				write !, "1. Early surrender allowed"
				write !, "2. Late surrender allowed"
				write !, "3. No surrender allowed"
				write !
				read tChoice2#1
				if (tChoice2 = "") { quit}
				if (tChoice2 = 1) { set %Table.SurrenderAllowed = "Early" quit }
				if (tChoice2 = 2) { set %Table.SurrenderAllowed = "Late" quit }
				if (tChoice2 = 3) { set %Table.SurrenderAllowed = "None" quit }
			}
		}
		if (tChoice1 = 3) {
			for {
				write !,!, "Select one or press Enter to leave choice as: "_%Table.DoublingAllowed
				write !, "1. Double on any two cards"
				write !, "2. Double on 9, 10, or 11 only"
				write !, "3. Double on 10 or 11 only"
				write !
				read tChoice2#1
				if (tChoice2 = "") { quit}
				if (tChoice2 = 1) { set %Table.DoublingAllowed = "Any" quit }
				if (tChoice2 = 2) { set %Table.DoublingAllowed = "9-10-11 Only" quit }
				if (tChoice2 = 3) { set %Table.DoublingAllowed = "10-11 Only" quit }
			}
		}
		if (tChoice1 = 4) {
			for {
				write !, "Enter a number 2 - 9 or press Enter to leave choice as: "_%Table.MaxHandsPerSeat
				write !
				read tChoice2#1
				if (tChoice2 = "") { quit}
				if ((tChoice2>=2)&&(tChoice2<=9)) { set %Table.MaxHandsPerSeat = tChoice2 quit }
			}
		}
		if (tChoice1 = 5) {
			for {
				write !,!, "Select one or press Enter to leave choice as: "_%Table.DoubleAfterSplitAllowed
				write !, "0. Double after split NOT allowed."
				write !, "1. Double after split allowed."
				write !
				read tChoice2#1
				if (tChoice2 = "") { quit}
				if ("01"[tChoice2) { set %Table.DoubleAfterSplitAllowed = tChoice2 quit }
			}
		}
		if (tChoice1 = 6) {
			for {
				write !,!, "Select one or press Enter to leave choice as: "_%Table.HitSplitAcesAllowed
				write !, "0. Split aces MAY NOT be hit."
				write !, "1. Split aces may be hit."
				write !
				read tChoice2#1
				if (tChoice2 = "") { quit}
				if ("01"[tChoice2) { set %Table.HitSplitAcesAllowed = tChoice2 quit }
			}
		}
		if (tChoice1 = 7) {
			for {
				write !,!, "Select one or press Enter to leave choice as: "_%Table.ResplittingAcesAllowed
				write !, "0. Aces MAY NOT be re-split."
				write !, "1. Aces may be re-split."
				write !
				read tChoice2#1
				if (tChoice2 = "") { quit}
				if ("01"[tChoice2) { set %Table.ResplittingAcesAllowed = tChoice2 quit }
			}
		}
		if (tChoice1 = 8) {
			for {
				write !!, "Enter the number of decks the game is played with or press Enter to leave as: "_%Table.Shoe.NumberOfDecks
				write !
				read tChoice2
				if (tChoice2 = "") { quit }
				set %Table.Shoe.NumberOfDecks = tChoice2
				quit
			}
		}
		if (tChoice1 = "q") { quit}
	}
}

ClassMethod SetSimParams()
{
	for {
		do %Table.Print(0)
		write !, "Choose or press Enter to go back to Main Menu."
		write !, "1. When game pauses if no humans in the game (Currently: "_%Sim("HumanlessPauses",%Sim("HumanlessPauses"))_")"
		read !,">>",tChoice#1
		if (tChoice = "") { quit }
		if (tChoice = 1) {
			for {
				do %Table.Print(0)
				write !, "Select one or press Enter to leave unchanged."
				write !, "1. Pause only when the player runs out of money."
				write !, "2. Above + Pause when the shoe is shuffled."
				write !, "3. Above + Pause when a hand is over."
				write !, "4. Above + Pause for any table action."
				read !, ">>", tChoice#1
				if (tChoice = "") { quit }
				if ((tChoice >= 1)&&(tChoice <= 4)) {
					set %Sim("HumanlessPauses") = tChoice
					read !, "Parameter updated. Press any key to continue.", tDummy#1
					quit
				}
			}
		}
	}
}

ClassMethod Game()
{
	//Initialize (shuffle + fill) the shoe
	do %Table.Shoe.Shuffle()
	
	set (%HandsDealt,%DealerWins,%PlayerWinsNonBJ,%PlayerWinsBJ,%Pushes,%Surrenders,%CorrectMoves,%IncorrectMoves) = 0
	//Each iteration of this loop is one game.
	for {
		write #
		set %HandsDealt = %HandsDealt + 1
		set %Table.DealerShowingHoleCard = 0
		do %Table.Print()
		//Create players' hands.  At this point their bets are taken from their bankrolls.
		for tSeatNum=1:1:%Table.NumberOfSeats {
			if %Table.HasPlayerAtSeat(tSeatNum) {
				set tPlayer = %Table.Players(tSeatNum)
				set tHand = ##class(Trainer.Hand).%New()
				set tHand.Bet = tPlayer.GetBet()
				do tPlayer.Hands.Insert(tHand)
				set tPlayer.Bankroll = tPlayer.Bankroll - tHand.Bet
			}
		}
		do %Table.Print()
		
		//Initial deal. Deal a card to players 1-<n>, then the dealer, then again.
		for i=1:1:2 {
			for tSeatNum=1:1:%Table.NumberOfSeats {
				if %Table.HasPlayerAtSeat(tSeatNum) {
					do %Table.Players(tSeatNum).Hands.GetAt(1).GetDealtCard(%Table.Shoe.DealCard())
					do %Table.Print()
				}
			}
			do %Table.DealersHand.GetDealtCard(%Table.Shoe.DealCard())
			do %Table.Print()
		}
		
		//Before playing the hand, handle blackjacks
		//First, the dealer either has blackjack or he doesn't.
		if (%Table.DealersHand.IsBlackjack()) {
			set %Table.DealerShowingHoleCard = 1
			do %Table.Print()
			//Then, the players either have blackjack or they don't
			for tSeatNum=1:1:%Table.NumberOfSeats {
				if %Table.HasPlayerAtSeat(tSeatNum) {
					set tPlayer = %Table.Players(tSeatNum)
					if (%Table.Players(tSeatNum).Hands.GetAt(1).IsBlackjack()) {
						//Dealer and player have blackjack.  Push.
						if ('tPlayer.IsComputer) { set %Pushes = %Pushes + 1 }
					}
					else {
						//Dealer has blackjack and player doesn't.  Player loses.
						set tPlayer.Hands.GetAt(1).Bet = 0
						if ('tPlayer.IsComputer) { set %DealerWins = %DealerWins + 1 }
					}
					do %Table.Print()
				}
			}
			//If the dealer has blackjack, the hand is over here.
			goto HandOver
		}
		//Now check for player blackjacks
		else {
			for tSeatNum=1:1:%Table.NumberOfSeats {
				if %Table.HasPlayerAtSeat(tSeatNum) {
					set tPlayer = %Table.Players(tSeatNum)
					//At this point the player only has one hand.
					set tHand = tPlayer.Hands.GetAt(1)
					if (tHand.IsBlackjack()) {
						//Player has blackjack and dealer doesn't.  Payout is 1.5 to 1.
						set tHand.Winnings = (1.5*tHand.Bet)
						if ('tPlayer.IsComputer) { set %PlayerWinsBJ = %PlayerWinsBJ + 1 }
						do %Table.Print()
						set tHand.Cards = ""
						do %Table.Print()
					}
				}
			}
			//Only proceed if there are hands left (ie not everyone got blackjack)
			if ('%Table.HandsLeft()) {
				set %Table.DealerShowingHoleCard = 1
				do %Table.Print()
				goto HandOver
			}
		}
		//Now neither dealer nor remaining players have blackjack; let's play some cards.

		for tSeatNum=1:1:%Table.NumberOfSeats {
			if %Table.HasPlayerAtSeat(tSeatNum) {
				set tPlayer = %Table.Players(tSeatNum)
				set tHandNum = 1
PlayerLoopStart
				set tHand = tPlayer.Hands.GetAt(tHandNum)
				if (tHand = "") { continue }
				if (tHand.Cards = "") { continue } //hand was a blackjack
				//Handle the case where this is a split hand needing its second card.
				if (tHand.Size = 1) {
					do tHand.GetDealtCard(%Table.Shoe.DealCard())
					do %Table.Print()
				}
				//If a human player, this will ask the player for their action.
				//If a computer player, this will get the correct action according to
				//that player's strategy.
				set tAction = tPlayer.GetAction(%Table.DealersUpCard(), tHand)
				
				//Now carry out player's action
				//Hit
				if (tAction = "H") {
					do tHand.GetDealtCard(%Table.Shoe.DealCard())
					do %Table.Print()
					
					//If a bust, remove cards and bet.
					if (tHand.Value > 21) { 
						set tHand.Cards = ""
						set tHand.Bet = 0
						do %Table.Print()
						
						if ('tPlayer.IsComputer) { set %DealerWins = %DealerWins + 1 }
						set tHandNum = tHandNum + 1
					}
				}
				//Stand
				//Player is done with hand, go on to next one
				elseif (tAction = "S") {
					set tHandNum = tHandNum + 1
				}
				//Split
				//Create a new hand with the second card of this hand
				//and return to beginning of loop.  Dealing the second card
				//to each hand will be handled there.  Each hand's bet is equal
				//to the original bet.
				elseif (tAction = "P") {
					set tNewHand = ##class(Trainer.Hand).%New()
					set tNewHand.Cards = $P(tHand.Cards, ",", 2)
					set tNewHand.WasSplit = 1
					set tNewHand.Bet = tHand.Bet
					set tPlayer.Bankroll = tPlayer.Bankroll - tNewHand.Bet
					do tPlayer.Hands.Insert(tNewHand)
					set tHand.Cards = $P(tHand.Cards, ",", 1)
					set tHand.WasSplit = 1
					do %Table.Print()
				}
				//Double
				//Player doubles their bet and gets exactly one more card
				//TODO: Implement doubling for less
				elseif (tAction = "D") {
					set tPlayer.Bankroll = tPlayer.Bankroll - tHand.Bet
					set tHand.Bet = 2*tHand.Bet
					do %Table.Print()
					
					do tHand.GetDealtCard(%Table.Shoe.DealCard())
					do %Table.Print()
					
					//If a bust, remove cards and bet
					if (tHand.Value > 21) { 
						set tHand.Cards = ""
						set tHand.Bet = 0
						do %Table.Print()
						
						if ('tPlayer.IsComputer) { set %DealerWins = %DealerWins + 1 }
					}
					//Increment tHandNum to move on to next hand
					set tHandNum = tHandNum + 1 
				}
				//Surrender
				//Player gives up the hand and receives back half of their original bet
				elseif (tAction = "U") {
					set tHand.Bet = tHand.Bet/2
					do %Table.Print()
					
					set tHand.Cards = ""
					do %Table.Print()
					
					if ('tPlayer.IsComputer) { set %Surrenders = %Surrenders + 1 }
					set tHandNum = tHandNum + 1
				}
				//Quit
				//Immediately quit the game
				elseif (tAction = "Q") {
					goto Exit
				}
				//Debug
				//Ask the user for a statement to execute and execute it.
				elseif (tAction = "W") {
					write !, "Enter statement to execute."
					read !, x
					xecute x
				}
				goto PlayerLoopStart
			}
		}
		
		//Done taking the players' actions, now the dealer plays his hand, but only if there are still
		//players' hands still in the game.
		set %Table.DealerShowingHoleCard = 1
		do %Table.Print()
		
		if ('%Table.HandsLeft()) { goto HandOver }
		//Dealer hits if his hand is less than 17 or is a soft 17 and the table rules are that he hits on this
		while ((%Table.DealersHand.Value < 17)||
		       ((%Table.DealersHand.SimplifiedHand = "A,6")&&(%Table.DealerHitsSoft17))
		      ) {
			do %Table.DealersHand.GetDealtCard(%Table.Shoe.DealCard())
			do %Table.Print()
		}
		
		//Dealer's hand is played, now determine win/loss/push for each player hand left
		for tSeatNum=1:1:%Table.NumberOfSeats {
			if %Table.HasPlayerAtSeat(tSeatNum) {
				set tPlayer = %Table.Players(tSeatNum)
				set tHandNum = 1
PayoffLoopStart
				set tHand = tPlayer.Hands.GetAt(tHandNum)
				if (tHand = "") {
					//Out of hands.  Done with this player.
					continue 
				}
				//if no cards, the player either busted or got blackjack, so go on to the next hand.
				if (tHand.Size = 0) { }
				elseif ((%Table.DealersHand.Value > 21)||(tHand.Value > %Table.DealersHand.Value)) {
					set tHand.Winnings = tHand.Bet
					if ('tPlayer.IsComputer) { set %PlayerWinsNonBJ = %PlayerWinsNonBJ + 1 }
				}
				//else if dealer wins
				elseif ((%Table.DealersHand.Value<= 21)&&(%Table.DealersHand.Value > tHand.Value)) {
					set tHand.Bet = 0
					if ('tPlayer.IsComputer) { set %DealerWins = %DealerWins + 1 }
				}
				//else if push
				elseif (%Table.DealersHand.Value = tHand.Value) {
					if ('tPlayer.IsComputer) { set %Pushes = %Pushes + 1 }
				}
				//Nothing should fall outside these cases but put a catch-all block with some debugging just in case.
				else {
					write !, "Error: For some reason I couldn't determine the outcome of this hand."
					write !, "Here is a terminal prompt for debugging purposes, press Enter on an empty line when done."
					for {
						read !, ">>", x
						if (x = "") { quit }
						xecute x
					}
				}
				do %Table.Print()
				
				set tHandNum = tHandNum + 1
				goto PayoffLoopStart
			}
		}
		
HandOver
		for tSeatNum=1:1:%Table.NumberOfSeats {
			if %Table.HasPlayerAtSeat(tSeatNum) {
				set tPlayer = %Table.Players(tSeatNum)
				set tHandNum = 1
				for {
					set tHand = tPlayer.Hands.GetAt(tHandNum)
					if (tHand = "") { quit }
					set tPlayer.Bankroll = tPlayer.Bankroll + tHand.Bet + tHand.Winnings
					do tPlayer.Hands.RemoveAt(tHandNum)
					do %Table.Print()			
				}
			}
		}
		
		set %Table.DealersHand.Cards = ""
		if (%Table.Shoe.ShuffleNeeded) {
			write !, "Shuffling shoe...", !
			do %Table.Shoe.Shuffle()
			if (('%Table.HumansAtTable)&&(%Sim("HumanlessPauses") >= 2)) {
				read !, "Press any key to continue.", tDummy#1
			}
		}
		
		//In this loop check to see if any players are out of money
		for tSeatNum = 1:1:%Table.NumberOfSeats {
			if (%Table.HasPlayerAtSeat(tSeatNum)) {
				set tPlayer = %Table.Players(tSeatNum)
				//Should never be < 0, but just in case
				if (tPlayer.Bankroll <= 0) {
					write !, "Player "_tSeatNum_" is out of money. What should they do?"
					write !, "1. Buy back in"
					write !, "2. Leave the table"
					for {
						read !, ">>", tChoice#1
						if (tChoice = 1) {
							write !, "Buy back in for how much?"
							for {
								read !, ">>", tBankroll
								if (tBankroll > 0) { quit }
							}
							set tPlayer.Bankroll = tBankroll
							write !, "Player "_tSeatNum_" bought back in for $"_tBankroll_"."
							read !, "Press any key to continue.", tDummy#1
							quit
						}
						if (tChoice = 2) {
							do %Table.RemovePlayer(tSeatNum)
							write !, "Player "_tSeatNum_" left the table."
							read !, "Press any key to continue.", tDummy#1
							quit
						}
					}
				}
				do %Table.Print(0)
			}
		}
		//If no players left at the table return to main menu.
		if (%Table.Players = 0) { goto Exit }
		if (('%Table.HumansAtTable)&&(%Sim("HumanlessPauses") < 3)) { continue }
MetaStart
		set tMetaAction = "*"
		while ("1Q" '[ tMetaAction) {
			write !, "Hand is over.  What would you like to do now?"
			write !, "<Enter> - Start next hand"
			write !, "1 - Change a player's unit bet"
			write !, "Q - Quit to main menu"
			read !,">>",tMetaAction#1
			set tMetaAction = $ZCVT(tMetaAction, "U")
		}
		if (tMetaAction = "") { continue }
		elseif (tMetaAction = 1) {
			for {
				read !, "Player at which seat? ", tSeatNum#1
				if (tSeatNum = "") { continue }
				if (%Table.HasPlayerAtSeat(tSeatNum)) {
					set tPlayer = %Table.Players(tSeatNum)
				}
				else { continue }
			}
			set tNewBet = 0
			while (tNewBet '> 0) {
				read !, "New bet? ", tNewBet
			}
			set tPlater.UnitBet = tNewBet
			read !, "Unit bet changed. Press any key to continue.", tDummy#1
			do %Table.Print(0)
			goto MetaStart
		}
		elseif (tMetaAction = "Q") { goto Exit }
	}
Exit
	quit
}

/// TODO: provide correct strategy matrices for different table rules.
/// Initiates %StrategyMatrix array.<br>
/// To get correct action from %StrategyMatrix:<br>
/// <nbsp><nbsp><nbsp><nbsp>$E(%StrategyMatric([Dealer's up card]), %HandIndex([player's simplified hand])) = [correct action]<br>
/// Actions are abbreviated as:<br>
/// H = Hit<br>
/// S = Stand<br>
/// P = Split<br>
/// D = Double (Hit if not allowed)<br>
/// O = Double (Stand if not allowed)<br>
/// U = Surrender (Hit if not allowed)<br>
/// R = Surrender (Stand if not allowed)<br>
ClassMethod Init()
{
	kill %HandIndex, %StrategyMatrix
	set tHands = "5^6^7^8^9^10^11^12^13^14^15^16^17^A,2^A,3^A,4^A,5^A,6^A,7^A,8^A,9^2,2^3,3^4,4^5,5^6,6^7,7^8,8^9,9^10,10^A,A"
	set tI = 1
	for tI=1:1:31 {
		set tHand = $P(tHands, "^", tI)
		set %HandIndex(tHand) = tI
	}

	set %StrategyMatrix(2)   = "HHHHHDDHSSSSSHHHHHOSSPPHDPPPPSP"
	set %StrategyMatrix(3)   = "HHHHDDDHSSSSSHHHHDOSSPPHDPPPPSP"
	set %StrategyMatrix(4)   = "HHHHDDDSSSSSSHHDDDOSSPPHDPPPPSP"
	set %StrategyMatrix(5)   = "HHHHDDDSSSSSSDDDDDOSSPPPDPPPPSP"
	set %StrategyMatrix(6)   = "HHHHDDDSSSSSSDDDDDOOSPPPDPPPPSP"
	set %StrategyMatrix(7)   = "HHHHHDDHHHHHSHHHHHSSSPPHDHPPSSP"
	set %StrategyMatrix(8)   = "HHHHHDDHHHHHSHHHHHSSSHHHDHHPPSP"
	set %StrategyMatrix(9)   = "HHHHHDDHHHHUSHHHHHHSSHHHDHHPPSP"
	set %StrategyMatrix(10)  = "HHHHHHDHHHURSHHHHHHSSHHHHHHPSSP"
	set %StrategyMatrix("A") = "HHHHHHDHHHUURHHHHHHSSHHHHHHUSSP"
	
	set %Explanation(9)       = "Double against 3-4-5-6, otherwise hit."
	set %Explanation(10)      = "ALWAYS double a 10 EXCEPT against 10 or A."
	set %Explanation(11)      = "ALWAYS double 11."
	set %Explanation(12)      = "Stand against 4-5-6, otherwise hit.  12 is the only time you hit when heads up."
	set %Explanation(13)      = "Stand to 6, otherwise hit."
	set %Explanation(14)      = "Stand to 6, otherwise hit."
	set %Explanation(15)      = "Stand to 6, hit to 9, surrender to 10-A."
	set %Explanation(16)      = "Stand to 6, hit to 8, surrender to 9-10-A."
	set %Explanation(17)      = "ALWAYS stand on 17 EXCEPT against an A, then surrender."
	set %Explanation("A,2")   = "Double against 5-6, otherwise hit."
	set %Explanation("A,3")   = "Double against 5-6, otherwise hit."
	set %Explanation("A,4")   = "Double against 4-5-6, otherwise hit."
	set %Explanation("A,5")   = "Double against 4-5-6, otherwise hit."
	set %Explanation("A,6")   = "Double against 3-4-5-6, otherwise hit."
	set %Explanation("A,7")   = "Double/Stand to 6, stand to 8, hit 9-10-A."
	set %Explanation("A,8")   = "Double/Stand against 6, otherwise stand."
	set %Explanation("A,9")   = "ALWAYS stand."
	set %Explanation("2,2")   = "Split to 7, otherwise hit."
	set %Explanation("3,3")   = "Split to 7, otherwise hit."
	set %Explanation("4,4")   = "Split against 5-6, otherwise hit."
	set %Explanation("5,5")   = "Same as 10: double to 9, otherwise hit."
	set %Explanation("6,6")   = "Split to 6, otherwise hit."
	set %Explanation("7,7")   = "Split to 7, otherwise hit."
	set %Explanation("8,8")   = "ALWAYS split 8s, EXCEPT against A, then surrender/hit."
	set %Explanation("9,9")   = "Stand against 7-10-A, otherwise split."
	set %Explanation("10,10") = "ALWAYS stand with 10s."
	set %Explanation("A,A")   = "ALWAYS split As."
}

}

