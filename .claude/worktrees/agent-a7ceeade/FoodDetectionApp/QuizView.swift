import SwiftUI

struct QuizQuestion {
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

struct QuizView: View {
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int?
    @State private var score = 0
    @State private var questionsAnswered = 0
    @State private var showExplanation = false
    @State private var quizComplete = false
    @State private var sessionQuestions: [QuizQuestion] = []
    @State private var xpAwarded = false

    private let questionsPerSession = 4

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Nutrition Quiz")
                            .font(.title2.bold())
                        Text("Test your nutrition knowledge")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(score)/\(questionsPerSession)")
                            .font(.headline)
                    }
                }
                .padding(.horizontal)

                if quizComplete {
                    // Quiz Complete
                    VStack(spacing: 16) {
                        Image(systemName: score >= 3 ? "trophy.fill" : "hand.thumbsup.fill")
                            .font(.system(size: 60))
                            .foregroundColor(score >= 3 ? .yellow : .blue)

                        Text("Quiz Complete!")
                            .font(.title.bold())

                        Text("You scored \(score) out of \(questionsPerSession)")
                            .font(.title3)

                        Text(scoreMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        if score >= 3 && !xpAwarded {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("+10 XP Earned!")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(10)
                        }

                        Button(action: startNewQuiz) {
                            Text("Play Again")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                } else if !sessionQuestions.isEmpty {
                    // Progress
                    ProgressView(value: Double(questionsAnswered), total: Double(questionsPerSession))
                        .tint(.blue)
                        .padding(.horizontal)

                    Text("Question \(questionsAnswered + 1) of \(questionsPerSession)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    let question = sessionQuestions[currentQuestionIndex]

                    // Question Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text(question.question)
                            .font(.title3.bold())
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(0..<question.options.count, id: \.self) { index in
                            Button(action: {
                                if selectedAnswer == nil {
                                    selectAnswer(index)
                                }
                            }) {
                                HStack {
                                    Text(optionLetter(index))
                                        .font(.headline)
                                        .foregroundColor(answerColor(index, question: question))
                                        .frame(width: 30)

                                    Text(question.options[index])
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)

                                    Spacer()

                                    if let selected = selectedAnswer {
                                        if index == question.correctIndex {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else if index == selected && selected != question.correctIndex {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding()
                                .background(answerBackground(index, question: question))
                                .cornerRadius(12)
                            }
                            .disabled(selectedAnswer != nil)
                        }

                        // Explanation
                        if showExplanation {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text("Explanation")
                                        .font(.headline)
                                }
                                Text(question.explanation)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(12)

                            Button(action: nextQuestion) {
                                Text(questionsAnswered + 1 >= questionsPerSession ? "See Results" : "Next Question")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(14)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .onAppear {
            if sessionQuestions.isEmpty {
                startNewQuiz()
            }
        }
    }

    // MARK: - Actions

    func selectAnswer(_ index: Int) {
        selectedAnswer = index
        let question = sessionQuestions[currentQuestionIndex]
        if index == question.correctIndex {
            score += 1
        }
        showExplanation = true
    }

    func nextQuestion() {
        questionsAnswered += 1
        if questionsAnswered >= questionsPerSession {
            quizComplete = true
            awardXP()
        } else {
            currentQuestionIndex += 1
            selectedAnswer = nil
            showExplanation = false
        }
    }

    func startNewQuiz() {
        sessionQuestions = Array(Self.questionBank.shuffled().prefix(questionsPerSession))
        currentQuestionIndex = 0
        selectedAnswer = nil
        score = 0
        questionsAnswered = 0
        showExplanation = false
        quizComplete = false
        xpAwarded = false
    }

    func awardXP() {
        guard score >= 3 else { return }
        // Guard against double awarding
        let lastAwardKey = "quiz_last_xp_award"
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = UserDefaults.standard.object(forKey: lastAwardKey) as? Date,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return
        }
        UserDefaults.standard.set(today, forKey: lastAwardKey)

        let currentXP = UserDefaults.standard.integer(forKey: "user_xp")
        UserDefaults.standard.set(currentXP + 10, forKey: "user_xp")
        xpAwarded = true
    }

    var scoreMessage: String {
        switch score {
        case 4: return "Perfect score! You're a nutrition expert!"
        case 3: return "Great job! You know your nutrition well!"
        case 2: return "Not bad! Keep learning about nutrition."
        case 1: return "Room for improvement. Try reading more about nutrition!"
        default: return "Don't worry, learning is a journey. Try again!"
        }
    }

    func optionLetter(_ index: Int) -> String {
        ["A", "B", "C", "D"][index]
    }

    func answerColor(_ index: Int, question: QuizQuestion) -> Color {
        guard let selected = selectedAnswer else { return .blue }
        if index == question.correctIndex { return .green }
        if index == selected { return .red }
        return .gray
    }

    func answerBackground(_ index: Int, question: QuizQuestion) -> Color {
        guard let selected = selectedAnswer else { return Color(UIColor.tertiarySystemBackground) }
        if index == question.correctIndex { return Color.green.opacity(0.1) }
        if index == selected { return Color.red.opacity(0.1) }
        return Color(UIColor.tertiarySystemBackground)
    }

    // MARK: - Question Bank (50 Questions)
    static let questionBank: [QuizQuestion] = [
        QuizQuestion(question: "Which macronutrient provides the most calories per gram?",
                     options: ["Protein", "Carbohydrates", "Fats", "Fiber"],
                     correctIndex: 2, explanation: "Fats provide 9 calories per gram, while protein and carbs provide 4 each."),
        QuizQuestion(question: "What is the recommended daily water intake for adults?",
                     options: ["1 liter", "2-3 liters", "5 liters", "500ml"],
                     correctIndex: 1, explanation: "Most health authorities recommend 2-3 liters (8-12 cups) per day."),
        QuizQuestion(question: "Which vitamin is produced when skin is exposed to sunlight?",
                     options: ["Vitamin A", "Vitamin B12", "Vitamin C", "Vitamin D"],
                     correctIndex: 3, explanation: "Vitamin D is synthesized in the skin upon exposure to UVB radiation."),
        QuizQuestion(question: "What is the primary function of protein in the body?",
                     options: ["Energy storage", "Building and repairing tissues", "Regulating body temperature", "Absorbing vitamins"],
                     correctIndex: 1, explanation: "Proteins are the building blocks of muscles, organs, and tissues."),
        QuizQuestion(question: "Which food is the richest source of omega-3 fatty acids?",
                     options: ["Chicken breast", "Salmon", "White rice", "Bananas"],
                     correctIndex: 1, explanation: "Fatty fish like salmon are excellent sources of EPA and DHA omega-3s."),
        QuizQuestion(question: "How many essential amino acids must be obtained from food?",
                     options: ["5", "7", "9", "20"],
                     correctIndex: 2, explanation: "There are 9 essential amino acids that the body cannot synthesize."),
        QuizQuestion(question: "Which mineral is most important for bone health?",
                     options: ["Iron", "Calcium", "Sodium", "Potassium"],
                     correctIndex: 1, explanation: "Calcium is the primary mineral component of bones and teeth."),
        QuizQuestion(question: "What does BMR stand for?",
                     options: ["Body Mass Ratio", "Basal Metabolic Rate", "Basic Muscle Recovery", "Body Measurement Result"],
                     correctIndex: 1, explanation: "BMR is the number of calories your body needs at complete rest."),
        QuizQuestion(question: "Which of these is a complete protein source?",
                     options: ["Rice", "Beans", "Eggs", "Bread"],
                     correctIndex: 2, explanation: "Eggs contain all 9 essential amino acids, making them a complete protein."),
        QuizQuestion(question: "What is the glycemic index (GI) a measure of?",
                     options: ["Protein content", "Fat content", "How quickly food raises blood sugar", "Calorie density"],
                     correctIndex: 2, explanation: "GI ranks carbohydrates by how quickly they raise blood glucose levels."),
        QuizQuestion(question: "Which vitamin is essential for blood clotting?",
                     options: ["Vitamin A", "Vitamin C", "Vitamin K", "Vitamin E"],
                     correctIndex: 2, explanation: "Vitamin K is essential for the synthesis of blood clotting factors."),
        QuizQuestion(question: "How many calories are in 1 gram of alcohol?",
                     options: ["4", "7", "9", "0"],
                     correctIndex: 1, explanation: "Alcohol provides 7 calories per gram, between carbs/protein (4) and fat (9)."),
        QuizQuestion(question: "Which nutrient helps prevent constipation?",
                     options: ["Protein", "Fat", "Fiber", "Cholesterol"],
                     correctIndex: 2, explanation: "Dietary fiber adds bulk to stool and promotes regular bowel movements."),
        QuizQuestion(question: "What is the main source of energy for the brain?",
                     options: ["Protein", "Fat", "Glucose", "Vitamins"],
                     correctIndex: 2, explanation: "The brain primarily uses glucose (from carbohydrates) as its fuel source."),
        QuizQuestion(question: "Which food contains the most iron per serving?",
                     options: ["Spinach", "Milk", "Apple", "White bread"],
                     correctIndex: 0, explanation: "Spinach is one of the richest plant-based sources of iron."),
        QuizQuestion(question: "What is the recommended daily sodium intake?",
                     options: ["500mg", "1500mg", "2300mg or less", "5000mg"],
                     correctIndex: 2, explanation: "The Dietary Guidelines recommend less than 2,300mg of sodium per day."),
        QuizQuestion(question: "Which type of fat is considered the healthiest?",
                     options: ["Trans fat", "Saturated fat", "Monounsaturated fat", "Hydrogenated fat"],
                     correctIndex: 2, explanation: "Monounsaturated fats (found in olive oil, avocados) are heart-healthy."),
        QuizQuestion(question: "What percentage of your plate should be vegetables?",
                     options: ["10%", "25%", "50%", "75%"],
                     correctIndex: 2, explanation: "The USDA MyPlate recommends filling half your plate with fruits and vegetables."),
        QuizQuestion(question: "Which B vitamin is important during pregnancy?",
                     options: ["B1 (Thiamine)", "B6", "B9 (Folate)", "B12"],
                     correctIndex: 2, explanation: "Folate (B9) is crucial for preventing neural tube defects in babies."),
        QuizQuestion(question: "What is the thermic effect of food?",
                     options: ["Food temperature", "Calories burned digesting food", "Cooking heat required", "Food preservation method"],
                     correctIndex: 1, explanation: "TEF is the energy expended to digest, absorb, and process nutrients."),
        QuizQuestion(question: "Which antioxidant gives tomatoes their red color?",
                     options: ["Beta-carotene", "Lycopene", "Anthocyanin", "Chlorophyll"],
                     correctIndex: 1, explanation: "Lycopene is a powerful antioxidant that gives tomatoes their red pigment."),
        QuizQuestion(question: "How much protein do adults generally need per kg of body weight?",
                     options: ["0.2g", "0.5g", "0.8g", "2.0g"],
                     correctIndex: 2, explanation: "The RDA for protein is 0.8g per kg of body weight for sedentary adults."),
        QuizQuestion(question: "Which food is highest in potassium?",
                     options: ["Chicken", "Banana", "White rice", "Cheese"],
                     correctIndex: 1, explanation: "Bananas are well-known for their high potassium content (~422mg each)."),
        QuizQuestion(question: "What is intermittent fasting?",
                     options: ["Eating only vegetables", "Cycling between eating and fasting periods", "Eating one meal a day", "Fasting for a week"],
                     correctIndex: 1, explanation: "IF involves alternating cycles of eating and fasting, such as 16:8 or 5:2."),
        QuizQuestion(question: "Which nutrient is most calorie-dense?",
                     options: ["Carbohydrate", "Protein", "Fat", "Alcohol"],
                     correctIndex: 2, explanation: "Fat has 9 calories per gram, making it the most calorie-dense macronutrient."),
        QuizQuestion(question: "What does HDL cholesterol stand for?",
                     options: ["Heavy Density Lipoprotein", "High Density Lipoprotein", "Healthy Diet Level", "Hyper Dense Lipid"],
                     correctIndex: 1, explanation: "HDL stands for High-Density Lipoprotein, often called 'good' cholesterol."),
        QuizQuestion(question: "Which fruit has the most vitamin C per serving?",
                     options: ["Apple", "Banana", "Kiwi", "Grape"],
                     correctIndex: 2, explanation: "Kiwi has about 71mg of vitamin C per fruit, more than an orange."),
        QuizQuestion(question: "What is the main role of carbohydrates?",
                     options: ["Build muscle", "Provide energy", "Absorb vitamins", "Fight infection"],
                     correctIndex: 1, explanation: "Carbohydrates are the body's primary and preferred source of energy."),
        QuizQuestion(question: "Which cooking method retains the most nutrients?",
                     options: ["Deep frying", "Boiling", "Steaming", "Grilling at high heat"],
                     correctIndex: 2, explanation: "Steaming preserves water-soluble vitamins better than boiling or frying."),
        QuizQuestion(question: "What is a caloric surplus?",
                     options: ["Eating fewer calories than you burn", "Eating more calories than you burn", "Eating exactly your TDEE", "Skipping meals"],
                     correctIndex: 1, explanation: "A caloric surplus means consuming more energy than you expend, leading to weight gain."),
        QuizQuestion(question: "Which mineral helps regulate blood pressure?",
                     options: ["Calcium", "Iron", "Potassium", "Zinc"],
                     correctIndex: 2, explanation: "Potassium helps balance sodium levels and relaxes blood vessel walls."),
        QuizQuestion(question: "What is TDEE?",
                     options: ["Total Daily Exercise Expenditure", "Total Daily Energy Expenditure", "Total Dietary Energy Estimate", "Thermal Diet Effect Equation"],
                     correctIndex: 1, explanation: "TDEE represents the total calories you burn in a day including activity."),
        QuizQuestion(question: "Which food group is the best source of dietary fiber?",
                     options: ["Meat", "Dairy", "Whole grains", "Eggs"],
                     correctIndex: 2, explanation: "Whole grains, fruits, and vegetables are the best sources of dietary fiber."),
        QuizQuestion(question: "What happens if you eat too little protein?",
                     options: ["Weight gain", "Muscle loss", "Better sleep", "Faster metabolism"],
                     correctIndex: 1, explanation: "Insufficient protein leads to muscle wasting, weakness, and slower recovery."),
        QuizQuestion(question: "Which is NOT a function of water in the body?",
                     options: ["Temperature regulation", "Nutrient transport", "Energy production", "Joint lubrication"],
                     correctIndex: 2, explanation: "Water does not produce energy; it regulates temperature, transports nutrients, and lubricates joints."),
        QuizQuestion(question: "What is the healthiest way to consume fruits?",
                     options: ["As juice with added sugar", "Whole and fresh", "Canned in syrup", "Dried with added sugar"],
                     correctIndex: 1, explanation: "Whole fresh fruits retain their fiber, vitamins, and have no added sugars."),
        QuizQuestion(question: "Which type of carbohydrate is digested most slowly?",
                     options: ["Simple sugars", "Refined starches", "Complex carbohydrates", "Glucose"],
                     correctIndex: 2, explanation: "Complex carbs (whole grains, legumes) are digested slowly, providing sustained energy."),
        QuizQuestion(question: "What is the primary source of vitamin A?",
                     options: ["Citrus fruits", "Carrots and sweet potatoes", "Dairy only", "Grains"],
                     correctIndex: 1, explanation: "Orange vegetables like carrots and sweet potatoes are rich in beta-carotene (vitamin A)."),
        QuizQuestion(question: "How long does it take for the stomach to empty after a meal?",
                     options: ["30 minutes", "1 hour", "2-4 hours", "8 hours"],
                     correctIndex: 2, explanation: "Gastric emptying typically takes 2-4 hours depending on meal composition."),
        QuizQuestion(question: "Which nutrient is important for immune function?",
                     options: ["Vitamin C", "Cholesterol", "Saturated fat", "Caffeine"],
                     correctIndex: 0, explanation: "Vitamin C supports immune cell function and acts as an antioxidant."),
        QuizQuestion(question: "What is the Mediterranean diet rich in?",
                     options: ["Red meat", "Processed foods", "Olive oil, fish, and vegetables", "Sugary drinks"],
                     correctIndex: 2, explanation: "The Mediterranean diet emphasizes olive oil, fish, whole grains, and fresh produce."),
        QuizQuestion(question: "Which organ produces insulin?",
                     options: ["Liver", "Kidneys", "Pancreas", "Stomach"],
                     correctIndex: 2, explanation: "The pancreas produces insulin to regulate blood sugar levels."),
        QuizQuestion(question: "What is the recommended daily fiber intake?",
                     options: ["5g", "10g", "25-30g", "50g"],
                     correctIndex: 2, explanation: "Adults should aim for 25-30g of fiber daily for optimal digestive health."),
        QuizQuestion(question: "Which fat is found in avocados?",
                     options: ["Trans fat", "Saturated fat", "Monounsaturated fat", "No fat"],
                     correctIndex: 2, explanation: "Avocados are rich in heart-healthy monounsaturated fatty acids."),
        QuizQuestion(question: "What does 'empty calories' mean?",
                     options: ["Zero-calorie foods", "Foods high in calories but low in nutrients", "Diet foods", "Burned calories"],
                     correctIndex: 1, explanation: "Empty calories come from foods with lots of energy but little nutritional value (e.g., soda, candy)."),
        QuizQuestion(question: "Which meal timing strategy may boost metabolism?",
                     options: ["Skipping breakfast always", "Eating most calories at night", "Eating regular, balanced meals", "Eating one large meal"],
                     correctIndex: 2, explanation: "Regular balanced meals help maintain steady metabolism and blood sugar levels."),
        QuizQuestion(question: "What is the role of probiotics?",
                     options: ["Build muscle", "Support gut bacteria", "Increase bone density", "Reduce cholesterol only"],
                     correctIndex: 1, explanation: "Probiotics are beneficial bacteria that support digestive health and immunity."),
        QuizQuestion(question: "Which food is a good source of plant-based protein?",
                     options: ["White rice", "Lentils", "Lettuce", "Cucumber"],
                     correctIndex: 1, explanation: "Lentils provide about 18g of protein per cooked cup, making them an excellent plant protein."),
        QuizQuestion(question: "How many calories does one pound of body fat contain?",
                     options: ["1000", "2500", "3500", "5000"],
                     correctIndex: 2, explanation: "One pound of body fat is approximately equivalent to 3,500 calories."),
        QuizQuestion(question: "Which electrolyte is lost most during sweating?",
                     options: ["Calcium", "Potassium", "Sodium", "Magnesium"],
                     correctIndex: 2, explanation: "Sodium is the primary electrolyte lost through sweat during exercise.")
    ]
}
