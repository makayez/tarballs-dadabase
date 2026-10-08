-- Modules/WarcraftJokes.lua - World of Warcraft Themed Jokes Module

Dadabase = Dadabase or {}

local defaultJokes = {
    "My friend keeps saying 'cheer up druid it could be worse, you could be stuck underground in a hole full of water.' I know he means well.",
    "What has more letters than the alphabet? The Dalaran mail room.",
    "Where do shamans go to get an education? Elementary school",
    "Someone keeps sending me flowers with the heads cut off... I think a druid is stalking me",
    "What do you call a forsaken without a body and a nose? Nobody nose",
    "How do you know someone's been playing since Vanilla? Don't worry, they'll tell you.",
    "You would think that a snail mount without a shell would move that bit faster? But it's actually more sluggish.",
    "What did the mechanical frog battle pet say? Rivet Rivet",
    "When I raid I never worried about my fingers. I can always count on them",
    "What do you call a death knight who shows up out of nowhere? Sir-prise",
    "I got a job at a Westfall farm but I resigned because they didn't have horses. I wanted something more stable",
    "Why did Lord Chamberlain block the toilets in Darkhaven? The enema overflows.",
    "One of my Alliance friend trolls so much he should have gone Horde",
    "What is Alexstrasza's favorite instrument? The Wyrmrest accordion.",
    "How many dwarves does it take to screw in a lightbulb? Two. One to hold the light bulb in place and the other to drink until the room starts spinning",
    "What do you call a druid who melees in tree form? A combat log.",
    "How does Naxxramas fly? With its four wings.",
    "Garrosh walks into a bar. The horde and the alliance form a line and punch him. Thats the punchline.",
    "Where does Ragnaros go for his back treatments? The pyro-practor",
    "Feral: Why do I always get drunk and fail my finals? Boomkin: You should stack int",
    "What do you call a tauren rogue? Invisibull",
    "My son, a fire mage, asked me 'Mom, are we pyromaniacs?' I responded, 'Yes we arson'.",
    "If the Queen Azshara accidentally farts during battle, pretend like nothing happens. Noble gasses should have no reaction",
    "Why do druids hate math? It gives them square roots.",
    "Why did Bwonsamdi crossed the road? To get to de other side",
    "Why does Monty, the gnomish flute player in Deeprun Tram, never miss a beat? He's a metro-gnome.",
    "What do you call a death knight who doesn't wash? Sir Melly!",
    "What do you call 3 restro druids walking across private property? Trees passing",
    "You know you have been playing WoW for too long when the microwave dings and you yell 'GRATS!'",
    "What do rogues and noobs have in common? They both pick locks.",
    "I asked Katy Stampwhistle for help with posting a pachyderm. I was having trouble addressing the elephant in the room",
    "How many Blizzard developers does it take to get an expansion right? Nobody knows yet",
    "I told my shadowlands gear that I loved it... It burst into tiers!",
    "Plague, mana, and even Goblin-engineered.  When it comes to the Horde artillery, Theramore bombs",
    "What is a good Kul Tiran team building activity? The Drust fall",
    "How does a druid cut their hair? 'Eclipse it.",
    "How do you stop a Warrior from charging? You take away his credit card",
    "They say that you can safely fit 3 people on the expedition yak mount without a problem. I thought that sounded easy but finding 3 people without a problem is pretty hard.",
    "What's the abbreviation for Death Knight? Decay",
    "Bolvar had a full set of hair... He should be called Baldvar now.",
    "Why can shadow priests get away with not doing mechanics? Because they can just use a-vrm.",
    "They say vulpera are wanderers and merchants, but few know of their reverence for sliced meats and cheeses. Their spiritual leader and head caravaner? The Deli Llama.",
    "Why aren't warriors using intellect enchants? Because they don't want their weapons to be smarter than themselves",
    "What's a rogue's favourite drink? Subtle tea.",
    "Why did the engineer create a robot fish battle pet? He wanted more e-fish in sea",
    "You know you're addicted to WoW when the only reason you go to church is for the stam buff",
    "Why are Taurens so tired after giving birth? Because they have been de-calf-inated",
    "What do you call it if a fire mage and paladin share a bath? A hot tub with bubbles",
    "So one of my druid friends thought getting travel form would help him get girls... Sadly, he goes stag everywhere.",
    "What do you call a Tauren Demon Hunter? Illidairy",
    "A paladin watered an avocado tree with holy water so they could make 'Holy Guacamole'",
    "What did the kul tiran crewmates find when they looked in the toilet? The captain's log",
    "A forsaken was searching for more help with his understaffed ship. All he had was a skeleton crew",
    "Chromie was going to tell a time traveling joke... But you guys didn't like it.",
    "Who designs Kul Tiran pirate ships? ARGHHitects. Caaaarrrrrrrpenters build them and they have a large arrrrrrrrr&d department",
    "Why did the Kul'tirans settle in the southeastern area? Because they loved how Tiragarde Sounds",
    "Why do worgan druids turn into cats? Because otherwise it would be ruff",
    "Why are guardian druids the best tanks for M+? They know all the best roots.",
    "What do you get if you cross a gnome and a tauren? A mini-taur.",
    "What do you call a sleepy balance druid? A napkin",
    "I am really disappointed that it is called The Dark Portal and not... Orc de Triomphe",
    "Why don't you startle Garrosh? Hellscream!",
    "How come people get lost in Thunder Bluff? Because the layout makes a real mesa things",
    "Why do hunters get smashed in bars? Because they're always multi-shotting",
    "A young rogue robbed the Stormwind bank using a reflection prism but later turned himself in. Luckily, the judge was lenient as he saw a lot of himself in the man.",
    "Did you know that bells are one of the most requested items for Tauren player models? Mainly because their horns don't work.",
    "Did you know that the Centaurs are generally considered attention seeking by the other races of Azeroth? Some say that they can't help but be the centaur of attention.",
    "I asked a restro druid for help with my herb garden. They gave me some sage advice",
    "Why did the enchanter have to clean out his bank? Because it was full of dust",
    "What did the orc yell to his companions after discovering the Un'goro Tar Pits? Look, tar!",
    "Why didn't the undead cross the road? He didn't have the guts",
    "If Anduin is King in Elwynn Forest, what is he in Redridge Mountains? Hiking",
    "What's a druid's favorite drink? Root beer",
    "What do you call 5 mogu rolling down the hill? The Rolling Stones",
    "A hunter missed their wedding because they disengaged",
    "How do you email your guildmates in Bastion? You just click a-send",
    "Why did the naaru ask for a loan? It's because they were a bit light on money.",
    "How do Forsaken without noses smell? Terrible!",
    "Recent survey revealed 6 out of 7 dwarf's aren't happy.",
    "You have now! Did you hear Chromies time travel joke?",
    "The treant Gnarlgar is a frail leader with a mysterious aura, bad breath, and rough feet from walking everywhere... He is a super-calloused-fragile-mystic-hexed-by-halitosis.",
    "Where do Kul Tiran pirates get their hooks? Second hand stores",
    "What did the restro druid say about the girl they didn't know? I've never met herbivore.",
    "What's a warlock's favorite drink? Shardonnay"
}

-- Register with Database Manager
Dadabase.DatabaseManager:RegisterModule("warcraftjokes", {
    name = "Warcraft Jokes",
    defaultContent = defaultJokes,
    dbVersion = 1,
    defaultSettings = {
        enabled = false,
        groups = {
            raid = false,
            party = false
        }
    }
})

-- Register config tab
Dadabase.Config:RegisterModuleTab("warcraftjokes", {
    name = "Warcraft Jokes",
    buildContent = function(container, moduleId)
        Dadabase.Config:BuildModuleContent(container, moduleId)
    end
})
