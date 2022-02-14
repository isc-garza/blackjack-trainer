Class Trainer.Shoe Extends %RegisteredObject
{

/// The number of decks this game is played with.
Property NumberOfDecks As %Integer [ InitialExpression = 6 ];

/// The cards in the shoe.
Property Cards As %ListOfDataTypes;

/// When this many cards are left in the shoe, set ShuffleNeeded to 1
Property BlankCardPosition As %Integer;

/// TODO: Implement practice modes (shoes that only deal pairs, only deal hands with aces, etc.)
Property PracticeMode As %String;

Property ShuffleNeeded As %Boolean [ InitialExpression = 0 ];

/// Initialize the shoe by shuffling
Method Shuffle()
{
	set tSC = ..Cards.Clear()
	
	for i=1:1:..NumberOfDecks
	{	for tSuit=1:1:4  //We don't care about the actual suit at this point, maybe in the future (doubt it though).
		{
			for tCard = 2,3,4,5,6,7,8,9,10,"J","Q","K","A"
			{	
				do ..Cards.Insert(tCard)
			}
		}
	}
	//Set the blank card two decks from the end of the shoe, plus or minus half a deck, chosen randomly
	set ..BlankCardPosition = (2.5*52)-$RANDOM(53)
	set ..ShuffleNeeded = 0
	set %DecksRemaining = ..NumberOfDecks
	set %Count = 0
	
	quit
}

/// TODO: Eventually, counting will have to be implemented in the player classes because there
/// are different ways of counting.  A way of "broadcasting" cards dealt to the players will 
/// be needed.  Also, using this method, the dealer's hole card is counted before it can be
/// seen by the players.
Method DealCard() As %String
{
	if (..Cards.Count() = ..BlankCardPosition) { set ..ShuffleNeeded = 1 }
	set tCard = ..Cards.RemoveAt($RANDOM(..Cards.Count())+1)
	if (",2,3,4,5,6,"[(","_tCard_",")) { set %Count = %Count + 1 }
	elseif (",10,J,Q,K,A,"[(","_tCard_",")) { set %Count = %Count - 1 }
	//TODO: Rather than producing this exact number, use an approximation.  Better yet,
	//come up with some visual indicator so I have to figure it out on my own.
	set %DecksRemaining = ..Cards.Count() / 52
	quit tCard
}

}

