import Foundation

struct CustomCategory: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var emoji: String
    var aisle: String
    var color: String       // hex soft bg
    var textColor: String
    var accentColor: String
    var builtin: Bool
}

// MARK: - Default Categories
let defaultCategories: [CustomCategory] = [
    .init(id: "produce",    name: "Fruit & Vegetables",  emoji: "🥦", aisle: "Front Wall / Produce", color: "#E8F5E9", textColor: "#2E7D32", accentColor: "#43A047", builtin: true),
    .init(id: "meat",       name: "Meat & Seafood",       emoji: "🥩", aisle: "Market / Seafood",     color: "#FCE4EC", textColor: "#AD1457", accentColor: "#E91E63", builtin: true),
    .init(id: "bakery",     name: "Bakery & Bread",       emoji: "🍞", aisle: "Bakery / Tortilleria", color: "#FFF8E1", textColor: "#F57F17", accentColor: "#FB8C00", builtin: true),
    .init(id: "dairy",      name: "Dairy & Eggs",         emoji: "🥛", aisle: "Dairy Wall",           color: "#E3F2FD", textColor: "#1565C0", accentColor: "#1E88E5", builtin: true),
    .init(id: "deli",       name: "Deli & Prepared Food", emoji: "🥪", aisle: "Deli / Meal Simple",   color: "#FFF3E0", textColor: "#BF360C", accentColor: "#F4511E", builtin: true),
    .init(id: "pantry",     name: "Pantry & Dry Goods",   emoji: "🥫", aisle: "Aisles 4–16",          color: "#F3E5F5", textColor: "#6A1B9A", accentColor: "#8E24AA", builtin: true),
    .init(id: "frozen",     name: "Frozen Food",          emoji: "🧊", aisle: "Frozen Doors",         color: "#E8EAF6", textColor: "#283593", accentColor: "#3949AB", builtin: true),
    .init(id: "beverages",  name: "Beverages",            emoji: "🧃", aisle: "Aisle 6–7",            color: "#E0F7FA", textColor: "#00695C", accentColor: "#00ACC1", builtin: true),
    .init(id: "essentials", name: "Everyday Essentials",  emoji: "🧻", aisle: "Aisle 15–23",          color: "#ECEFF1", textColor: "#37474F", accentColor: "#546E7A", builtin: true),
    .init(id: "health",     name: "Health & Beauty",      emoji: "💊", aisle: "Aisle 18–22",          color: "#E8F5E9", textColor: "#1B5E20", accentColor: "#2E7D32", builtin: true),
    .init(id: "baby",       name: "Baby & Kids",          emoji: "🍼", aisle: "Aisle 23–30",          color: "#FFF9C4", textColor: "#F57F17", accentColor: "#F9A825", builtin: true),
    .init(id: "home",       name: "Home & Outdoor",       emoji: "🏠", aisle: "Aisle 16–27",          color: "#EFEBE9", textColor: "#4E342E", accentColor: "#6D4C41", builtin: true),
    .init(id: "pets",       name: "Pets",                 emoji: "🐾", aisle: "Aisle 26–28",          color: "#F9FBE7", textColor: "#558B2F", accentColor: "#7CB342", builtin: true),
    .init(id: "beer_wine",  name: "Beer & Wine",          emoji: "🍷", aisle: "Aisle 1–2",            color: "#FCE4EC", textColor: "#880E4F", accentColor: "#C2185B", builtin: true),
    .init(id: "floral",     name: "Floral",               emoji: "💐", aisle: "Floral Dept.",         color: "#F8BBD0", textColor: "#880E4F", accentColor: "#E91E63", builtin: true),
]

let colorPalette: [(color: String, textColor: String, accentColor: String)] = [
    ("#FFF3E0", "#E65100", "#FB8C00"),
    ("#E8EAF6", "#283593", "#5C6BC0"),
    ("#FCE4EC", "#880E4F", "#E91E63"),
    ("#E0F2F1", "#004D40", "#00897B"),
    ("#FFF8E1", "#F57F17", "#FFA000"),
    ("#F3E5F5", "#4A148C", "#7B1FA2"),
    ("#E8F5E9", "#1B5E20", "#388E3C"),
    ("#E3F2FD", "#0D47A1", "#1976D2"),
    ("#FBE9E7", "#BF360C", "#E64A19"),
    ("#F9FBE7", "#558B2F", "#7CB342"),
]

let defaultZoneLayouts: [String: ZoneLayout] = {
    let cols = 12.0, rows = 13.0
    func g(_ col: Double, _ colSpan: Double, _ row: Double, _ rowSpan: Double) -> ZoneLayout {
        ZoneLayout(x: (col-1)/cols, y: (row-1)/rows, w: colSpan/cols, h: rowSpan/rows)
    }
    return [
        "produce":    g(1,  4, 1,  2),
        "floral":     g(5,  2, 1,  2),
        "bakery":     g(7,  3, 1,  2),
        "deli":       g(10, 3, 1,  2),
        "meat":       g(1,  2, 3,  4),
        "dairy":      g(11, 2, 3,  5),
        "frozen":     g(11, 2, 8,  4),
        "pantry":     g(3,  4, 3,  4),
        "beverages":  g(7,  4, 3,  3),
        "beer_wine":  g(7,  4, 6,  2),
        "essentials": g(3,  3, 9,  3),
        "health":     g(6,  3, 9,  3),
        "home":       g(9,  2, 8,  3),
        "pets":       g(9,  2, 11, 2),
        "baby":       g(3,  4, 12, 2),
    ]
}()

let categoryItems: [String: [String]] = [
    "produce": ["Apples","Bananas","Avocados","Lemons","Limes","Oranges","Strawberries","Blueberries","Grapes","Watermelon","Mangoes","Broccoli","Spinach","Lettuce","Tomatoes","Onions","Garlic","Potatoes","Sweet Potatoes","Bell Peppers","Jalapeños","Cucumbers","Zucchini","Carrots","Celery","Corn","Mushrooms","Asparagus","Green Beans","Cilantro","Kale","Cabbage","Salad Kit"],
    "meat": ["Chicken Breast","Chicken Thighs","Ground Beef","Chuck Roast","Ribeye Steak","Sirloin Steak","Pork Chops","Pork Ribs","Bacon","Ham","Ground Turkey","Salmon Fillet","Tilapia","Shrimp","Crab Legs","Tuna Steak","Sausage Links","Smoked Sausage","Brisket","Chorizo","Hot Dogs","Lunch Meat","Pepperoni"],
    "bakery": ["Sourdough Bread","Wheat Bread","White Bread","Tortillas (Flour)","Tortillas (Corn)","Bagels","English Muffins","Croissants","Dinner Rolls","Hamburger Buns","Hot Dog Buns","Pita Bread","Naan","Muffins","Donuts","Kolaches","Cinnamon Rolls","French Bread","Bolillo Rolls","Pan Dulce"],
    "dairy": ["Whole Milk","2% Milk","Almond Milk","Oat Milk","Eggs (Large)","Eggs (Jumbo)","Butter","Cream Cheese","Cheddar Cheese","Mozzarella","Pepper Jack","Parmesan","Shredded Cheese","Sour Cream","Greek Yogurt","Heavy Cream","Half & Half","Cottage Cheese","String Cheese"],
    "deli": ["Sliced Turkey","Sliced Ham","Sliced Roast Beef","Salami","Rotisserie Chicken","Fried Chicken","Soup","Sushi","Guacamole (Fresh)","Pico de Gallo","Fresh Salsa","Hummus","Deli Salads","Sandwich","Wraps"],
    "pantry": ["Canned Tomatoes","Canned Beans","Canned Corn","Canned Tuna","Canned Soup","Chicken Broth","Pasta (Dry)","Rice","Oatmeal","Quinoa","Salsa","BBQ Sauce","Ketchup","Mustard","Mayonnaise","Olive Oil","Pickles","Peanut Butter","Flour","Sugar","Salt","Honey","Syrup","Spices","Cereal","Chips","Tortilla Chips","Crackers","Popcorn","Granola Bars","Macaroni & Cheese","Ramen"],
    "frozen": ["Frozen Pizza","Frozen Burritos","Frozen Meals","Frozen Chicken","Frozen Vegetables","Frozen Fruit","Frozen Berries","Hash Browns","Frozen Waffles","Ice Cream","Ice Cream Bars","Popsicles","Frozen Lasagna"],
    "beverages": ["Sodas / Coke","Diet Coke","Sprite","Dr Pepper","Water","Sparkling Water","Sports Drinks","Energy Drinks","Orange Juice","Apple Juice","Lemonade","Coffee","Tea (Bags)"],
    "beer_wine": ["Beer (Domestic)","Beer (Import)","Beer (Craft)","Hard Seltzer","Hard Cider","Red Wine","White Wine","Rosé","Sparkling Wine","Non-Alcoholic Beer"],
    "essentials": ["Paper Towels","Toilet Paper","Facial Tissue","Napkins","Aluminum Foil","Plastic Wrap","Trash Bags","Zip-Lock Bags","Laundry Detergent","Dish Soap","Dishwasher Detergent","All-Purpose Cleaner","Sponges"],
    "health": ["Vitamins","Protein Bars","Pain Reliever","Band-Aids","Antacids","Allergy Medicine","Toothpaste","Toothbrush","Mouthwash","Shampoo","Conditioner","Deodorant","Body Wash","Sunscreen","Feminine Hygiene","Cotton Balls"],
    "baby": ["Baby Food (Jars)","Baby Formula","Baby Snacks","Baby Wipes","Diapers","Baby Lotion","Baby Shampoo","Pull-Ups"],
    "home": ["Kitchen Gadgets","Bakeware","Charcoal","Party Supplies","Greeting Cards","Candles","Light Bulbs","Batteries","School Supplies"],
    "pets": ["Dry Dog Food","Wet Dog Food","Dog Treats","Dry Cat Food","Wet Cat Food","Cat Treats","Cat Litter","Flea & Tick Treatment"],
    "floral": ["Bouquet","Roses","Sunflowers","Lilies","Mixed Arrangement","Potted Plant","Orchid","Succulents","Balloons","Vase"],
]
