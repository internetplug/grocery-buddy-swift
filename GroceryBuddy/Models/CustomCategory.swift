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
    .init(id: "produce",     name: "Fruit & Vegetables",        emoji: "🥦", aisle: "", color: "#E8F5E9", textColor: "#2E7D32", accentColor: "#43A047", builtin: true),
    .init(id: "meat",        name: "Meat & Seafood",            emoji: "🥩", aisle: "", color: "#FCE4EC", textColor: "#AD1457", accentColor: "#E91E63", builtin: true),
    .init(id: "dairy",       name: "Dairy & Eggs",              emoji: "🥛", aisle: "", color: "#E3F2FD", textColor: "#1565C0", accentColor: "#1E88E5", builtin: true),
    .init(id: "deli",        name: "Deli Meats & Cheese",       emoji: "🧀", aisle: "", color: "#FFF3E0", textColor: "#BF360C", accentColor: "#F4511E", builtin: true),
    .init(id: "frozen",      name: "Frozen Food",               emoji: "🧊", aisle: "", color: "#E8EAF6", textColor: "#283593", accentColor: "#3949AB", builtin: true),
    .init(id: "soda",        name: "Soda",                      emoji: "🥤", aisle: "", color: "#E0F7FA", textColor: "#00695C", accentColor: "#00ACC1", builtin: true),
    .init(id: "essentials",  name: "Everyday Essentials",       emoji: "🧻", aisle: "", color: "#ECEFF1", textColor: "#37474F", accentColor: "#546E7A", builtin: true),
    .init(id: "health",      name: "Health & Beauty",           emoji: "💊", aisle: "", color: "#E0F2F1", textColor: "#004D40", accentColor: "#00897B", builtin: true),
    .init(id: "home",        name: "Home & Outdoor",            emoji: "🏠", aisle: "", color: "#EFEBE9", textColor: "#4E342E", accentColor: "#6D4C41", builtin: true),
    .init(id: "pets",        name: "Pets",                      emoji: "🐾", aisle: "", color: "#F9FBE7", textColor: "#558B2F", accentColor: "#7CB342", builtin: true),
    .init(id: "beer_wine",   name: "Beer & Wine",               emoji: "🍷", aisle: "", color: "#FCE4EC", textColor: "#880E4F", accentColor: "#C2185B", builtin: true),
    .init(id: "canned",      name: "Canned Soup & Foods",       emoji: "🥫", aisle: "", color: "#F3E5F5", textColor: "#6A1B9A", accentColor: "#8E24AA", builtin: true),
    .init(id: "pasta",       name: "Pasta & Pasta Sauce",       emoji: "🍝", aisle: "", color: "#FFF8E1", textColor: "#F57F17", accentColor: "#FFA000", builtin: true),
    .init(id: "baking",      name: "Baking, Oil & Spices",      emoji: "🧂", aisle: "", color: "#FBE9E7", textColor: "#BF360C", accentColor: "#E64A19", builtin: true),
    .init(id: "bread",       name: "Sliced Bread & Tortillas",  emoji: "🍞", aisle: "", color: "#FFE0B2", textColor: "#E65100", accentColor: "#EF6C00", builtin: true),
    .init(id: "condiments",  name: "Condiments, Rice, & Beans", emoji: "🌶️", aisle: "", color: "#FFEBEE", textColor: "#B71C1C", accentColor: "#E53935", builtin: true),
    .init(id: "candy_juice", name: "Candy & Juice",             emoji: "🍬", aisle: "", color: "#FFF3E0", textColor: "#E65100", accentColor: "#FB8C00", builtin: true),
    .init(id: "snacks",      name: "Chips, Crackers & Cookies", emoji: "🍪", aisle: "", color: "#FFF9C4", textColor: "#F57F17", accentColor: "#F9A825", builtin: true),
    .init(id: "bakery",      name: "Bakery",                    emoji: "🥐", aisle: "", color: "#EDE7F6", textColor: "#4527A0", accentColor: "#5E35B1", builtin: true),
    .init(id: "floral",      name: "Florist",                   emoji: "💐", aisle: "", color: "#F8BBD0", textColor: "#880E4F", accentColor: "#E91E63", builtin: true),
    .init(id: "prepared",    name: "Prepared Meals",            emoji: "🍱", aisle: "", color: "#FFCCBC", textColor: "#BF360C", accentColor: "#FF7043", builtin: true),
    .init(id: "seasonal",    name: "Seasonal Items",            emoji: "🎁", aisle: "", color: "#FFFDE7", textColor: "#F9A825", accentColor: "#FBC02D", builtin: true),
    .init(id: "misc",        name: "Miscellaneous",             emoji: "🛒", aisle: "", color: "#FAFAFA", textColor: "#424242", accentColor: "#616161", builtin: true),
]

let defaultZoneLayouts: [String: ZoneLayout] = {
    // Wide (landscape) store: 18 columns x 10 rows. Bottom row left clear for the
    // entrance/checkout strip. Perimeter fresh depts on the walls, aisles through the center.
    let cols = 18.0, rows = 10.0
    func g(_ col: Double, _ colSpan: Double, _ row: Double, _ rowSpan: Double) -> ZoneLayout {
        ZoneLayout(x: (col-1)/cols, y: (row-1)/rows, w: colSpan/cols, h: rowSpan/rows)
    }
    return [
        // Left wall
        "produce":     g(1,  3, 1, 3),
        "floral":      g(1,  3, 4, 2),
        "beer_wine":   g(1,  3, 6, 2),
        "pets":        g(1,  3, 8, 2),
        // Top wall
        "bakery":      g(4,  3, 1, 2),
        "deli":        g(7,  2, 1, 2),
        "prepared":    g(9,  2, 1, 2),
        "meat":        g(11, 5, 1, 2),
        // Center aisles
        "bread":       g(4,  2, 3, 3),
        "canned":      g(4,  2, 6, 4),
        "pasta":       g(6,  2, 3, 3),
        "baking":      g(6,  2, 6, 4),
        "condiments":  g(8,  2, 3, 3),
        "candy_juice": g(8,  2, 6, 4),
        "snacks":      g(10, 2, 3, 3),
        "soda":        g(10, 2, 6, 4),
        "essentials":  g(12, 2, 3, 3),
        "health":      g(12, 2, 6, 4),
        "home":        g(14, 2, 3, 3),
        "seasonal":    g(14, 2, 6, 2),
        "misc":        g(14, 2, 8, 2),
        // Right wall
        "dairy":       g(16, 3, 1, 5),
        "frozen":      g(16, 3, 6, 4),
    ]
}()

let categoryItems: [String: [String]] = [
    "produce": ["Apples","Bananas","Avocados","Lemons","Limes","Oranges","Strawberries","Blueberries","Grapes","Watermelon","Mangoes","Broccoli","Spinach","Lettuce","Tomatoes","Onions","Garlic","Potatoes","Sweet Potatoes","Bell Peppers","Jalapeños","Cucumbers","Zucchini","Carrots","Celery","Corn","Mushrooms","Asparagus","Green Beans","Cilantro","Kale","Cabbage","Salad Kit"],
    "meat": ["Chicken Breast","Chicken Thighs","Ground Beef","Chuck Roast","Ribeye Steak","Sirloin Steak","Pork Chops","Pork Ribs","Bacon","Ham","Ground Turkey","Salmon Fillet","Tilapia","Shrimp","Crab Legs","Tuna Steak","Sausage Links","Smoked Sausage","Brisket","Chorizo","Hot Dogs"],
    "dairy": ["Whole Milk","2% Milk","Almond Milk","Oat Milk","Eggs (Large)","Eggs (Jumbo)","Butter","Cream Cheese","Sour Cream","Greek Yogurt","Heavy Cream","Half & Half","Cottage Cheese","String Cheese","Shredded Cheese","Cheddar Cheese","Mozzarella","Yogurt Cups"],
    "deli": ["Sliced Turkey","Sliced Ham","Sliced Roast Beef","Salami","Pepperoni","Lunch Meat","Provolone","Swiss Cheese","Pepper Jack","Parmesan","Brie","Feta","Goat Cheese","Specialty Cheese","Olives"],
    "frozen": ["Frozen Pizza","Frozen Burritos","Frozen Meals","Frozen Chicken","Frozen Vegetables","Frozen Fruit","Frozen Berries","Hash Browns","Frozen Waffles","Ice Cream","Ice Cream Bars","Popsicles","Frozen Lasagna"],
    "soda": ["Sodas / Coke","Diet Coke","Sprite","Dr Pepper","Sparkling Water","Sports Drinks","Energy Drinks","Mineral Water","Root Beer","Ginger Ale"],
    "essentials": ["Paper Towels","Toilet Paper","Facial Tissue","Napkins","Aluminum Foil","Plastic Wrap","Trash Bags","Zip-Lock Bags","Laundry Detergent","Dish Soap","Dishwasher Detergent","All-Purpose Cleaner","Sponges"],
    "health": ["Vitamins","Pain Reliever","Band-Aids","Antacids","Allergy Medicine","Toothpaste","Toothbrush","Mouthwash","Shampoo","Conditioner","Deodorant","Body Wash","Sunscreen","Feminine Hygiene","Cotton Balls"],
    "home": ["Kitchen Gadgets","Bakeware","Charcoal","Party Supplies","Greeting Cards","Candles","Light Bulbs","Batteries","School Supplies"],
    "pets": ["Dry Dog Food","Wet Dog Food","Dog Treats","Dry Cat Food","Wet Cat Food","Cat Treats","Cat Litter","Flea & Tick Treatment"],
    "beer_wine": ["Beer (Domestic)","Beer (Import)","Beer (Craft)","Hard Seltzer","Hard Cider","Red Wine","White Wine","Rosé","Sparkling Wine","Non-Alcoholic Beer"],
    "canned": ["Canned Tomatoes","Canned Corn","Canned Tuna","Canned Soup","Chicken Broth","Vegetable Broth","Canned Chicken","Tomato Sauce","Canned Fruit","Diced Green Chilies","Tomato Paste"],
    "pasta": ["Pasta (Dry)","Spaghetti","Penne","Rotini","Macaroni","Lasagna Noodles","Egg Noodles","Pasta Sauce","Marinara","Alfredo Sauce","Pesto","Ramen"],
    "baking": ["Flour","Sugar","Brown Sugar","Powdered Sugar","Baking Powder","Baking Soda","Vanilla Extract","Olive Oil","Vegetable Oil","Cooking Spray","Salt","Pepper","Spices","Honey","Syrup","Yeast","Chocolate Chips"],
    "bread": ["Sourdough Bread","Wheat Bread","White Bread","Tortillas (Flour)","Tortillas (Corn)","Sandwich Bread","Hamburger Buns","Hot Dog Buns","Pita Bread","Naan","English Muffins","Bagels (Packaged)"],
    "condiments": ["Ketchup","Mustard","Mayonnaise","BBQ Sauce","Hot Sauce","Salsa","Soy Sauce","Salad Dressing","Pickles","Peanut Butter","Jelly","Rice","Quinoa","Canned Beans","Refried Beans","Black Beans","Pinto Beans"],
    "candy_juice": ["Orange Juice","Apple Juice","Lemonade","Grape Juice","Cranberry Juice","Fruit Punch","Chocolate Bars","Gummy Candy","Hard Candy","Mints","Gum","Lollipops","M&Ms"],
    "snacks": ["Chips","Tortilla Chips","Crackers","Popcorn","Granola Bars","Cookies","Pretzels","Cheese Crackers","Trail Mix","Nuts","Pita Chips","Goldfish","Cereal"],
    "bakery": ["Croissants","Dinner Rolls","Muffins","Donuts","Kolaches","Cinnamon Rolls","French Bread","Bolillo Rolls","Pan Dulce","Cake","Cupcakes","Pies","Cookies (Bakery)","Brownies"],
    "floral": ["Bouquet","Roses","Sunflowers","Lilies","Mixed Arrangement","Potted Plant","Orchid","Succulents","Balloons","Vase"],
    "prepared": ["Rotisserie Chicken","Fried Chicken","Soup","Sushi","Guacamole (Fresh)","Pico de Gallo","Fresh Salsa","Hummus","Deli Salads","Sandwich","Wraps","Meal Simple","Mac & Cheese (Prepared)","Pasta Salad"],
    "seasonal": ["Halloween Candy","Christmas Decor","Easter Eggs","Valentine's Chocolate","Summer Toys","BBQ Supplies","Pool Floats","Pumpkin Spice Items","Holiday Cookies","Greeting Cards (Seasonal)"],
    "misc": ["Gift Cards","Magazines","Newspaper","Reusable Bags","Phone Charger","Sunglasses","Hand Sanitizer","Travel Sizes"],
]
