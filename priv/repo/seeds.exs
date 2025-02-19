# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Monorepo.Repo.insert!(%Monorepo.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

industries = %{
  name: "Industries",
  slug: "industries",
  subcategories: [
    %{name: "Finance", slug: "finance", subcategories: [
      %{name: "Investment Platforms", slug: "investment-platforms"},
      %{name: "Financial Products", slug: "financial-products"},
      %{name: "Retirement Planning", slug: "retirement-planning"},
      %{name: "Wealth Management Tools", slug: "wealth-management-tools"},
      %{name: "Financial Advisors", slug: "financial-advisors"},
      %{name: "Asset Protection", slug: "asset-protection"},
      %{name: "Tax Planning", slug: "tax-planning"},
      %{name: "Corporate Tax Services", slug: "corporate-tax-services"}
    ]},

    %{name: "Insurance", slug: "insurance", subcategories: [
      %{name: "Health Insurance", slug: "health-insurance"},
      %{name: "Life Insurance", slug: "life-insurance"},
      %{name: "Property Insurance", slug: "property-insurance"},
      %{name: "Business Insurance", slug: "business-insurance"},
      %{name: "Insurance Planning", slug: "insurance-planning"}
    ]},

    %{name: "Stock", slug: "stock", subcategories: [
      %{name: "Stock Trading Platforms", slug: "stock-trading-platforms"},
      %{name: "Stock Analysis Tools", slug: "stock-analysis-tools"},
      %{name: "Stock Insights", slug: "stock-insights"},
      %{name: "Market Data", slug: "market-data"},
      %{name: "Investment Analysis", slug: "investment-analysis"}
    ]},

    %{name: "Wealth Management", slug: "wealth-management", subcategories: [
      %{name: "Personal Finance Tools", slug: "personal-finance-tools"},
      %{name: "Asset Allocation Tools", slug: "asset-allocation-tools"},
      %{name: "High-Net-Worth Wealth Management", slug: "high-net-worth-wealth-management"}
    ]},

    %{name: "Learning", slug: "learning", subcategories: [
      %{name: "Online Courses", slug: "online-courses"},
      %{name: "Career Training", slug: "career-training"},
      %{name: "Language Learning Platforms", slug: "language-learning-platforms"},
      %{name: "Professional Certifications", slug: "professional-certifications"},
      %{name: "English Learning", slug: "english-learning"}
    ]},

    %{name: "Recruitment", slug: "recruitment", subcategories: [
      %{name: "Online Recruitment Platforms", slug: "online-recruitment-platforms"},
      %{name: "Talent Search", slug: "talent-search"},
      %{name: "Talent Management Services", slug: "talent-management-services"},
      %{name: "Job Search", slug: "job-search"},
      %{name: "Recruitment Consultants", slug: "recruitment-consultants"}
    ]},

    %{name: "Travel", slug: "travel", subcategories: [
      %{name: "Luxury Travel Services", slug: "luxury-travel-services"},
      %{name: "Booking Platforms", slug: "booking-platforms"},
      %{name: "Luxury Vacation Packages", slug: "luxury-vacation-packages"},
      %{name: "Adventure Travel", slug: "adventure-travel"}
    ]},

    %{name: "Vacation", slug: "vacation", subcategories: [
      %{name: "Resorts & Luxury Vacation Packages", slug: "resorts-luxury-vacation-packages"},
      %{name: "Cruises", slug: "cruises"},
      %{name: "All-Inclusive Vacation Packages", slug: "all-inclusive-vacation-packages"}
    ]},

    %{name: "Luxury", slug: "luxury", subcategories: [
      %{name: "Luxury Bags & Jewelry", slug: "luxury-bags-jewelry"},
      %{name: "High-End Art & Collectibles", slug: "high-end-art-collectibles"},
      %{name: "Luxury Watches", slug: "luxury-watches"},
      %{name: "Designer Clothing", slug: "designer-clothing"}
    ]},

    %{name: "Personalization", slug: "personalization", subcategories: [
      %{name: "Customized Gifts", slug: "customized-gifts"},
      %{name: "Personalized Jewelry", slug: "personalized-jewelry"},
      %{name: "Customized Home Decor", slug: "customized-home-decor"},
      %{name: "Custom Clothing & Accessories", slug: "custom-clothing-accessories"}
    ]},

    %{name: "Custom Products", slug: "custom-products", subcategories: [
      %{name: "Custom Shoes", slug: "custom-shoes"},
      %{name: "Custom Bags", slug: "custom-bags"},
      %{name: "Custom Apparel", slug: "custom-apparel"},
      %{name: "Custom Electronics", slug: "custom-electronics"}
    ]},

    %{name: "Digital Products", slug: "digital-products", subcategories: [
      %{name: "E-books", slug: "ebooks"},
      %{name: "Digital Media", slug: "digital-media"},
      %{name: "Software Templates", slug: "software-templates"},
      %{name: "Design Resources", slug: "design-resources"},
      %{name: "Online Tools", slug: "online-tools"}
    ]},

    %{name: "Marketing Products", slug: "marketing-products", subcategories: [
      %{name: "SEO Tools", slug: "seo-tools"},
      %{name: "Online Marketing Tools", slug: "online-marketing-tools"},
      %{name: "Social Media Management", slug: "social-media-management"},
      %{name: "Marketing Automation", slug: "marketing-automation"},
      %{name: "Content Marketing Tools", slug: "content-marketing-tools"}
    ]},

    %{name: "IT Solution", slug: "it-solution", subcategories: [
      %{name: "IT Outsourcing", slug: "it-outsourcing"},
      %{name: "Enterprise IT Solutions", slug: "enterprise-it-solutions"},
      %{name: "Cloud Services", slug: "cloud-services"},
      %{name: "Cybersecurity Solutions", slug: "cybersecurity-solutions"},
      %{name: "Data Analytics & Big Data", slug: "data-analytics-big-data"},
      %{name: "Automation & RPA", slug: "automation-rpa"}
    ]},

    %{name: "Digital Electronics", slug: "digital-electronics", subcategories: [
      %{name: "Smart Home Products", slug: "smart-home-products"},
      %{name: "Wearables", slug: "wearables"},
      %{name: "Electronics Accessories", slug: "electronics-accessories"},
      %{name: "Headphones", slug: "headphones"},
      %{name: "Chargers", slug: "chargers"},
      %{name: "IoT Devices", slug: "iot-devices"}
    ]},

    %{name: "SaaS", slug: "saas", subcategories: [
      %{name: "CRM Tools", slug: "crm-tools"},
      %{name: "ERP Tools", slug: "erp-tools"},
      %{name: "Financial Management Tools", slug: "financial-management-tools"},
      %{name: "Team Collaboration Tools", slug: "team-collaboration-tools"},
      %{name: "Cloud Software", slug: "cloud-software"},
      %{name: "Project Management Tools", slug: "project-management-tools"}
    ]},

    %{name: "AI Agency", slug: "ai-agency", subcategories: [
      %{name: "AI Solutions", slug: "ai-solutions"},
      %{name: "Machine Learning Services", slug: "machine-learning-services"},
      %{name: "Text Generation (NLP)", slug: "text-generation-nlp"},
      %{name: "Natural Language Processing", slug: "natural-language-processing"},
      %{name: "Image Recognition", slug: "image-recognition"},
      %{name: "Speech Recognition", slug: "speech-recognition"},
      %{name: "Chatbots & Conversational AI", slug: "chatbots-conversational-ai"},
      %{name: "Predictive Analytics", slug: "predictive-analytics"},
      %{name: "Data Analytics & Big Data", slug: "data-analytics-big-data"},
      %{name: "Automation & Robotic Process Automation", slug: "automation-rpa"}
    ]},

    %{name: "Tax", slug: "tax", subcategories: [
      %{name: "Tax Planning", slug: "tax-planning"},
      %{name: "Corporate Tax Services", slug: "corporate-tax-services"}
    ]},

    %{name: "Collectibles", slug: "collectibles", subcategories: [
      %{name: "Art", slug: "art"},
      %{name: "Antiques", slug: "antiques"},
      %{name: "Limited-Edition Collectibles", slug: "limited-edition-collectibles"},
      %{name: "Sports Memorabilia", slug: "sports-memorabilia"}
    ]}
  ]
}

countries = [%{
  name: "Countries",
  slug: "countries",
  subcategories: [
    %{name: "United States", slug: "united-states"},
    %{name: "China", slug: "china"},
    %{name: "Japan", slug: "japan"},
    %{name: "Germany", slug: "germany"},
    %{name: "India", slug: "india"},
    %{name: "United Kingdom", slug: "united-kingdom"},
    %{name: "France", slug: "france"},
    %{name: "Italy", slug: "italy"},
    %{name: "Canada", slug: "canada"},
    %{name: "South Korea", slug: "south-korea"},
    %{name: "Brazil", slug: "brazil"},
    %{name: "Australia", slug: "australia"},
    %{name: "Russia", slug: "russia"},
    %{name: "Mexico", slug: "mexico"},
    %{name: "Spain", slug: "spain"},
    %{name: "Saudi Arabia", slug: "saudi-arabia"},
    %{name: "South Africa", slug: "south-africa"},
    %{name: "Indonesia", slug: "indonesia"},
    %{name: "Turkey", slug: "turkey"},
    %{name: "Netherlands", slug: "netherlands"},
    %{name: "Switzerland", slug: "switzerland"},
    %{name: "Sweden", slug: "sweden"},
    %{name: "Poland", slug: "poland"},
    %{name: "Belgium", slug: "belgium"},
    %{name: "Thailand", slug: "thailand"},
    %{name: "Singapore", slug: "singapore"},
    %{name: "Argentina", slug: "argentina"},
    %{name: "United Arab Emirates", slug: "united-arab-emirates"},
    %{name: "Nigeria", slug: "nigeria"},
    %{name: "Norway", slug: "norway"},
    %{name: "Malaysia", slug: "malaysia"},
    %{name: "Israel", slug: "israel"},
    %{name: "Austria", slug: "austria"},
    %{name: "Egypt", slug: "egypt"},
    %{name: "Chile", slug: "chile"},
    %{name: "Colombia", slug: "colombia"},
    %{name: "Pakistan", slug: "pakistan"},
    %{name: "Philippines", slug: "philippines"},
    %{name: "Vietnam", slug: "vietnam"},
    %{name: "Finland", slug: "finland"},
    %{name: "Denmark", slug: "denmark"},
    %{name: "Romania", slug: "romania"},
    %{name: "Ukraine", slug: "ukraine"},
    %{name: "Peru", slug: "peru"},
    %{name: "Bangladesh", slug: "bangladesh"},
    %{name: "Kazakhstan", slug: "kazakhstan"},
    %{name: "Kenya", slug: "kenya"},
    %{name: "Morocco", slug: "morocco"},
    %{name: "Sri Lanka", slug: "sri-lanka"},
    %{name: "Czech Republic", slug: "czech-republic"},
    %{name: "Slovakia", slug: "slovakia"},
    %{name: "Portugal", slug: "portugal"},
    %{name: "Greece", slug: "greece"},
    %{name: "Ireland", slug: "ireland"},
    %{name: "Bulgaria", slug: "bulgaria"},
    %{name: "Ecuador", slug: "ecuador"},
    %{name: "Jordan", slug: "jordan"},
    %{name: "Belarus", slug: "belarus"},
    %{name: "New Zealand", slug: "new-zealand"},
    %{name: "Qatar", slug: "qatar"},
    %{name: "Oman", slug: "oman"},
    %{name: "Luxembourg", slug: "luxembourg"},
    %{name: "Kuwait", slug: "kuwait"},
    %{name: "Trinidad and Tobago", slug: "trinidad-and-tobago"},
    %{name: "Cuba", slug: "cuba"},
    %{name: "Mongolia", slug: "mongolia"},
    %{name: "Iraq", slug: "iraq"},
    %{name: "Tanzania", slug: "tanzania"},
    %{name: "Uganda", slug: "uganda"},
    %{name: "Algeria", slug: "algeria"},
    %{name: "Angola", slug: "angola"},
    %{name: "Myanmar", slug: "myanmar"},
    %{name: "Cambodia", slug: "cambodia"},
    %{name: "Ethiopia", slug: "ethiopia"},
    %{name: "Armenia", slug: "armenia"},
    %{name: "Uzbekistan", slug: "uzbekistan"},
    %{name: "Macedonia", slug: "macedonia"},
    %{name: "Croatia", slug: "croatia"},
    %{name: "Latvia", slug: "latvia"},
    %{name: "Estonia", slug: "estonia"},
    %{name: "Lithuania", slug: "lithuania"},
    %{name: "Costa Rica", slug: "costa-rica"},
    %{name: "Honduras", slug: "honduras"},
    %{name: "Panama", slug: "panama"},
    %{name: "Bolivia", slug: "bolivia"},
    %{name: "Paraguay", slug: "paraguay"},
    %{name: "Guatemala", slug: "guatemala"},
    %{name: "El Salvador", slug: "el-salvador"},
    %{name: "Haiti", slug: "haiti"},
    %{name: "Hong Kong", slug: "hong-kong"},
    %{name: "Taiwan", slug: "taiwan"},
    %{name: "South Korea", slug: "south-korea"},
    %{name: "Macau", slug: "macau"},
    %{name: "Monaco", slug: "monaco"},
    %{name: "San Marino", slug: "san-marino"},
    %{name: "Liechtenstein", slug: "liechtenstein"},
    %{name: "Andorra", slug: "andorra"},
    %{name: "Luxembourg", slug: "luxembourg"}
  ]
}]



defmodule Monorepo.Seed do
  require Ash.Query
  require AshPostgres.DataLayer

  def term_upsert(inputs, parent_id) when is_list(inputs) do
    Enum.map(inputs, &(term_upsert(&1, parent_id)))
  end

  def term_upsert(%{name: name, slug: slug} = input, parent_id) when is_map(input) do
    term_taxonomy =
      case parent_id do
        nil -> [%{taxonomy: "category"}]
        parent_id ->
          [%{taxonomy: "category", parent_id: parent_id}]
      end

    insert_data =
      %Monorepo.Terms.Term{name: name, slug: slug, term_taxonomy: term_taxonomy}

    parent = Ash.Seed.upsert!(insert_data, actor: %{roles: [:admin]}, action: :create, identity: :unique_slug)

    if Map.has_key?(input, :subcategories) do
      Map.get(input, :subcategories)
      |> term_upsert(parent.id)
    end
  end
end

Monorepo.Seed.term_upsert(countries, nil)
Monorepo.Seed.term_upsert(industries, nil)
