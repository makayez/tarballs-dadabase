-- Modules/Demotivational.lua - Demotivational Sayings Module

Dadabase = Dadabase or {}

local defaultSayings = {
    "Remember: Failure is always an option.",
    "The only difference between you and a corpse is about 5 seconds.",
    "At least we're consistent.",
    "It's not a learning experience if we don't learn from it. So... same strat?",
    "Mistakes: Proof that you're trying. We're trying a LOT.",
    "If at first you don't succeed... lower your expectations.",
    "We're not bad, we're just differently successful.",
    "Every wipe is just another opportunity to wipe again.",
    "The floor tank strategy is bold. Not effective, but bold.",
    "Achievement Unlocked: Creative New Ways to Die",
    "Practice doesn't make perfect. As we've demonstrated.",
    "We're speedrunning... dying.",
    "That mechanic is optional, right? Right?",
    "Someone's gear broke. Was it our spirits? Yes.",
    "We put the 'fun' in 'funeral'.",
    "At this rate, we'll clear it by next expansion.",
    "I see the problem: We're not good enough.",
    "Well, we tried nothing and we're all out of ideas.",
    "Our DPS stands for 'Deaths Per Second'.",
    "We're not wiping, we're strategically repositioning to the graveyard.",
    "Remember when we thought this would be easy? Good times.",
    "The best ability is responsibility. We have neither.",
    "We didn't wipe. We performed a group tactical reset.",
    "Some say 'learn from mistakes.' We say 'make new ones!'",
    "Repair bills are just success tax. We're very successful.",
    "We're building character. And repair bills.",
    "We're not failing, we're discovering what doesn't work.",
    "Perhaps the real loot was the trauma we collected along the way.",
    "When in doubt, panic. We're following that strategy perfectly.",
    "Everything happens for a reason. Sometimes the reason is you're stupid and make bad decisions.",
    "Every dead body on Mt. Everest was once a highly motivated person, so… maybe calm down.",
    "Light travels faster than sound. This is why some people appear bright until you hear them speak.",
    "Just because we accept you as you are doesn't mean we've abandoned hope you'll improve.",
    "Idiocy - never underestimate the power of stupid people in large groups.",
    "We're not just bad, we're also unlucky.",
    "If life doesn't break you today, don't worry. It will try again tomorrow.",
    "People who say they'll give 110% don't understand how percentages work.",
    "A thousand-mile journey starts with one step. Then again, so does falling in a ditch and breaking your neck.",
    "If you never try anything new, you'll miss out on many of life's great disappointments",
    "If at first, you don't succeed, try, try again. Then quit. No use being a damn fool about it.",
    "It could be that your purpose in life is to serve as a warning to others.",
    "Today is the first day of the rest of your life. But so was yesterday, and look how that turned out.",
    "Always remember that you are absolutely unique. Just like everyone else.",
    "When life knocks you down, stay there and take a nap.",
    "Not everything is a lesson. Sometimes you just fail.",
    "Fate is like a strange, unpopular restaurant filled with odd little waiters who bring you things you never asked for and don't always like.",
    "The worst part of success is trying to find someone who is happy for you.",
    "Your life can't fall apart if you never had it together.",
    "The road to success is always under construction.",
    "Doing nothing is very hard to do… you never know when you're finished.",
    "The reward for good work is more work.",
    "Go ahead and take risks - it gives the rest of us something to laugh at.",
    "There's always someone on Youtube that can do it better than you.",
    "It's only when you look at an ant through a magnifying glass on a sunny day that you realize how often they burst into flames.",
    "If at first, you don't succeed, destroy all evidence that you tried.",
    "Stubbornness - because somebody has to be right and it might as well be me.",
    "Never give up. Never stop trying to exceed your limits. We need the entertainment.",
    "If you never believe in anything, you'll never be disappointed.",
    "Hope is the first step on the road to disappointment.",
    "I look at the world and see a rainbow of people who all suck in different ways.",
    "Raids - none of us is as dumb as all of us.",
    "Don't cry because it's over. Smile because if you don't, everyone will ask you what's wrong.",
    "TEAMWORK: A few harmless flakes working together can unleash an avalanche of destruction.",
    "The light at the end of the tunnel has been turned off due to budget cuts.",
    "Success is just a few bad decisions away.",
    "It's all downhill from here.",
    "Will it be easy? Nope. Worth it? Absolutely not!",
    "Happiness is just sadness that hasn't happened yet."
}

-- Register with Database Manager
Dadabase.DatabaseManager:RegisterModule("demotivational", {
    name = "Demotivational",
    defaultContent = defaultSayings,
    dbVersion = 2,
    defaultSettings = {
        enabled = false,
        triggers = {
            wipe = false,
            death = false
        },
        groups = {
            raid = false,
            party = false
        }
    }
})

-- Register config tab
Dadabase.Config:RegisterModuleTab("demotivational", {
    name = "Demotivational",
    buildContent = function(container, moduleId)
        Dadabase.Config:BuildModuleContent(container, moduleId)
    end
})
