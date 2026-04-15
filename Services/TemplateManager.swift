import Foundation
import SwiftUI

/// Static Singleton Repository providing high-converting advertising templates instantly to the UI layers.
/// Completely decoupled from ProfileManager. String injection occurs separately.
class TemplateManager: ObservableObject {
    
    @Published var baseTemplates: [ScriptTemplate] = []
    
    init() {
        self.loadDefaultTaxonomy()
    }
    
    private func loadDefaultTaxonomy() {
        
        // --- CATEGORY: EDUCATIONAL & PRESENTATION (.educational) ---
        let foundationPitch = ScriptTemplate(
            title: "The Foundation Pitch",
            description: "A fast, hyper-authoritative introduction perfectly positioning your brand.",
            bodyPattern: """
            Hi, I'm [BUSINESS_NAME] and we definitively solve [PAIN_POINT] for [USER_NICHE].
            
            Every single day, we see people struggling to get results because they are stuck using outdated methods.
            
            With [CORE_OFFER], we completely bypass that friction. 
            
            If you're ready to stop guessing and start scaling, check out the link in my bio right now.
            """,
            category: .educational
        )
        
        let mythBuster = ScriptTemplate(
            title: "The Myth-Buster",
            description: "Shock the system by tearing down a commonly held industry belief.",
            bodyPattern: """
            Here are 3 complete lies you've been told about [PAIN_POINT] as a [USER_NICHE].
            
            Lie number one: That you have to suffer entirely alone.
            Lie number two: That it costs a fortune to fix.
            Lie number three: That you don't need [CORE_OFFER].
            
            At [BUSINESS_NAME], we are proving all of them wrong. 
            """,
            category: .educational
        )
        
        let microTutorial = ScriptTemplate(
            title: "The Micro-Tutorial",
            description: "Value loop. Teach them a micro-skill before pitching the macro-solution.",
            bodyPattern: """
            As someone deep in the [USER_NICHE] space, here is exactly how you bypass [PAIN_POINT].
            
            Step 1: Audit your current systems.
            Step 2: Realize you are doing too much manual work.
            Step 3: Implement [CORE_OFFER].
            
            [BUSINESS_NAME] does the heavy lifting for you. Follow for part 2.
            """,
            category: .educational
        )
        
        // --- CATEGORY: DIRECT RESPONSE & SALES (.directResponse) ---
        let tiktokShowcase = ScriptTemplate(
            title: "The TikTok Shop Showcase",
            description: "Algorithmic physical or digital product showcase optimized for instant purchases.",
            bodyPattern: """
            Stop scrolling! If you constantly deal with [PAIN_POINT], this [CORE_OFFER] is exactly what you've been searching for.
            
            Thousands of [USER_NICHE] are already using [BUSINESS_NAME] to reclaim their time.
            
            It's literally 50% off in the TikTok Shop right now, but they usually sell out in hours.
            
            Tap the orange cart icon right here and grab yours before it's gone!
            """,
            category: .directResponse
        )
        
        let problemSolution = ScriptTemplate(
            title: "The Problem/Solution Agitator",
            description: "Agitate the customer's pain aggressively before delivering the antidote.",
            bodyPattern: """
            Are you completely exhausted trying to fix [PAIN_POINT]? 
            
            Here are 3 reasons why [CORE_OFFER] fixes it instantly.
            
            Number 1: It's specifically engineered for [USER_NICHE]. 
            Number 2: It bypasses the gatekeepers entirely.
            Number 3: [BUSINESS_NAME] guarantees it works.
            
            Don't waste another week. Check it out now.
            """,
            category: .directResponse
        )
        
        let competitorComparison = ScriptTemplate(
            title: "The Competitor Comparison",
            description: "Position yourself physically above the rest of the market.",
            bodyPattern: """
            Here is exactly why [BUSINESS_NAME] is absolutely dominating the rest of the market for [USER_NICHE].
            
            While everyone else is charging thousands just to leave you with [PAIN_POINT], we created [CORE_OFFER].
            
            It is faster, it is cheaper, and the ROI is immediate. 
            
            Don't get left behind.
            """,
            category: .directResponse
        )
        
        let hookToSale = ScriptTemplate(
            title: "The Hook-to-Sale Form",
            description: "Pure conversion mathematics pushing the user rapidly to checkout.",
            bodyPattern: """
            If you want to eliminate [PAIN_POINT], grab [CORE_OFFER] immediately.
            
            We built [BUSINESS_NAME] for exactly one reason: to serve [USER_NICHE]. 
            
            Click the link right here on the screen and checkout securely in under 30 seconds.
            """,
            category: .directResponse
        )
        
        // --- CATEGORY: UGC & HOOK FRAMEWORKS (.ugc) ---
        let originBackstory = ScriptTemplate(
            title: "The Origin & Backstory",
            description: "Build deep empathy and trust by revealing exactly why you started.",
            bodyPattern: """
            A year ago, I was completely overwhelmed, struggling with [PAIN_POINT].
            
            I was burning cash, testing everything, and nothing worked. That's exactly why I built [BUSINESS_NAME].
            
            I realized that [USER_NICHE] didn't need another generic solution. They needed exactly what we built into [CORE_OFFER].
            
            If you are tired of hitting the same wall, I made this for you. Link in bio.
            """,
            category: .ugc
        )
        
        let heroesJourney = ScriptTemplate(
            title: "The Hero's Journey",
            description: "A deeply narrative script capturing extreme emotional investment.",
            bodyPattern: """
            They told me it was impossible to fix [PAIN_POINT].
            
            But after hitting rock bottom, I refused to accept that [USER_NICHE] just had to suffer through it.
            
            So I spent the last two years engineering [CORE_OFFER]. It wasn't easy, and I failed dozens of times.
            
            But today, [BUSINESS_NAME] is helping hundreds finally break through. Follow me to see the exact blueprint.
            """,
            category: .ugc
        )
        
        // --- CATEGORY: VLOG & STORYTELLING (.vlog) ---
        let dayInTheLife = ScriptTemplate(
            title: "Day In The Life",
            description: "Highly engaging vlog format building quiet authority and deep parasocial connection.",
            bodyPattern: """
            Come with me on a 12-hour day building [BUSINESS_NAME].
            
            At 7 AM, I always review exactly why we're solving [PAIN_POINT] for [USER_NICHE].
            
            By lunchtime, I'm analyzing the results of [CORE_OFFER] to make sure our community is winning.
            
            If you want to see behind the scenes of what it actually takes, hit the follow button.
            """,
            category: .vlog
        )
        
        let epiphanyMoment = ScriptTemplate(
            title: "The Epiphany Moment",
            description: "Share the exact moment you realized your industry was broken and how you fixed it.",
            bodyPattern: """
            There was a single moment when I realized that dealing with [PAIN_POINT] was a complete scam. 
            
            I was talking to a top [USER_NICHE], and they confessed they were spending thousands and getting zero results.
            
            That's the exact moment I created [CORE_OFFER]. 
            
            If you want to avoid that trap entirely, click the link in my bio.
            """,
            category: .vlog
        )
        
        // --- CATEGORY: LISTICLES & QUICK-HITS (.listicle) ---
        let top3Tools = ScriptTemplate(
            title: "Top 3 Tools Matrix",
            description: "High-save-rate framework delivering rapid-fire list value immediately.",
            bodyPattern: """
            If you are a [USER_NICHE], you need to immediately save these 3 cheat codes to avoid [PAIN_POINT].
            
            Look at number one: Stop doing it manually and automate it.
            Number two: Never engage with the old framework.
            And most importantly, number three: Use [CORE_OFFER] to handle the entire backend instantly. 
            
            Save this video so you don't lose the blueprint!
            """,
            category: .listicle
        )
        
        let secretsRevealed = ScriptTemplate(
            title: "5 Secrets Nobody Tells You",
            description: "Curiosity-gap list format keeping viewer engaged through the final secret.",
            bodyPattern: """
            These are the 3 massive secrets the industry refuses to tell [USER_NICHE] about [PAIN_POINT].
            
            Secret 1: Most gurus don't even use the tools they preach.
            Secret 2: Real growth happens when you eliminate dead weight.
            Secret 3: [CORE_OFFER] will single-handedly outwork an entire team.
            
            Follow [BUSINESS_NAME] to stay ahead of the massive shift coming this year.
            """,
            category: .listicle
        )
        
        // --- CATEGORY: GROWTH & NETWORKING (.growth) ---
        let missionStatement = ScriptTemplate(
            title: "The Mission Statement",
            description: "Go broad, plant your flag, and declare what your brand stands for.",
            bodyPattern: """
            Our singular goal at [BUSINESS_NAME] is to help 10,000 [USER_NICHE] completely dominate and avoid [PAIN_POINT] forever.
            
            We are sick of the industry standard. We are tired of seeing people overpay for broken promises.
            
            With [CORE_OFFER], we are forcing a new standard. Join the movement.
            """,
            category: .growth
        )
        
        self.baseTemplates = [
            foundationPitch, mythBuster, microTutorial,
            tiktokShowcase, problemSolution, competitorComparison, hookToSale,
            originBackstory, heroesJourney,
            dayInTheLife, epiphanyMoment,
            top3Tools, secretsRevealed,
            missionStatement
        ]
    }
}
