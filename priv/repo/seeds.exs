# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Moly.Repo.insert!(%Moly.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

industries = %{
  name: "Industries",
  slug: "industries",
  subcategories: [
    %{
      name: "E-commerce",
      slug: "e-commerce",
      subcategories: [
        %{name: "Online Marketplaces", slug: "online-marketplaces"},
        %{name: "Fashion & Apparel", slug: "fashion-apparel"},
        %{name: "Home & Garden", slug: "home-garden"},
        %{name: "Electronics & Tech", slug: "electronics-tech"},
        %{name: "Wholesale & B2B", slug: "wholesale-b2b"},
        %{name: "Digital Products", slug: "digital-products"}
      ],
      term_meta: [%{term_key: "icon", term_value: "shopping-cart"}]
    },
    %{
      name: "Financial & Insurance",
      slug: "financial-insurance",
      subcategories: [
        %{name: "Investment Platforms", slug: "investment-platforms"},
        %{name: "Financial Products", slug: "financial-products"},
        %{name: "Retirement Planning", slug: "retirement-planning"},
        %{name: "Wealth Management Tools", slug: "wealth-management-tools"},
        %{name: "Financial Advisors", slug: "financial-advisors"},
        %{name: "Asset Protection", slug: "asset-protection"},
        %{name: "Health Insurance", slug: "health-insurance"},
        %{name: "Life Insurance", slug: "life-insurance"},
        %{name: "Property Insurance", slug: "property-insurance"},
        %{name: "Business Insurance", slug: "business-insurance"},
        %{name: "Insurance Planning", slug: "insurance-planning"}
      ],
      term_meta: [%{term_key: "icon", term_value: "credit-card"}]
    },
    %{
      name: "Wellness && Mental health",
      slug: "wellness-mental-health",
      subcategories: [
        %{name: "Telemedicine", slug: "telemedicine"},
        %{name: "Digital Health Records", slug: "digital-health-records"},
        %{name: "Medical Devices", slug: "medical-devices"},
        %{name: "Healthcare Software", slug: "healthcare-software"},
        %{name: "Mental Health Services", slug: "mental-health-services"},
        %{name: "Preventive Care", slug: "preventive-care"},
        %{name: "Personalized Medicine", slug: "personalized-medicine"},
        %{name: "Remote Patient Monitoring", slug: "remote-patient-monitoring"}
      ],
      term_meta: [%{term_key: "icon", term_value: "heart"}]
    },
    %{
      name: "Education & Learning",
      slug: "education-learning",
      subcategories: [
        %{name: "Online Courses", slug: "online-courses-education"},
        %{name: "Professional Certification", slug: "professional-certification-education"},
        %{name: "Language Learning", slug: "language-learning"},
        %{name: "Skills Development", slug: "skills-development"},
        %{name: "Corporate Training", slug: "corporate-training-education"},
        %{name: "Educational Technology", slug: "educational-technology"},
        %{name: "Test Preparation", slug: "test-preparation"},
        %{name: "Career Development", slug: "career-development-education"}
      ],
      term_meta: [%{term_key: "icon", term_value: "academic-cap"}]
    },
    %{
      name: "Digital Content & Services",
      slug: "digital-content-services",
      subcategories: [
        %{name: "Digital Art & NFTs", slug: "digital-art-nfts"},
        %{name: "Virtual Goods", slug: "virtual-goods"},
        %{name: "Digital Services", slug: "digital-services"},
        %{name: "Content Creation", slug: "content-creation"},
        %{name: "Digital Entertainment", slug: "digital-entertainment"},
        %{name: "Virtual Events", slug: "virtual-events"}
      ],
      term_meta: [%{term_key: "icon", term_value: "video-camera"}]
    },
    %{
      name: "AI & Technology",
      slug: "ai-technology",
      subcategories: [
        %{name: "AI Assistants", slug: "ai-assistants"},
        %{name: "Business AI Solutions", slug: "business-ai-solutions"},
        %{name: "AI Content Generation", slug: "ai-content-generation"},
        %{name: "AI Analytics", slug: "ai-analytics"},
        %{name: "AI Development Tools", slug: "ai-development-tools"},
        %{name: "AI Research Services", slug: "ai-research-services"},
        %{name: "AI Consulting", slug: "ai-consulting"},
        %{name: "Machine Learning Solutions", slug: "machine-learning-solutions"}
      ],
      term_meta: [%{term_key: "icon", term_value: "cpu-chip"}]
    },
    %{
      name: "Stock Trading & Wealth Management",
      slug: "stock-trading-wealth-management",
      subcategories: [
        %{name: "Stock Trading Platforms", slug: "stock-trading-platforms"},
        %{name: "Stock Analysis Tools", slug: "stock-analysis-tools"},
        %{name: "Stock Insights", slug: "stock-insights"},
        %{name: "Market Data", slug: "market-data"},
        %{name: "Investment Analysis", slug: "investment-analysis"},
        %{name: "Personal Finance Tools", slug: "personal-finance-tools"},
        %{name: "Asset Allocation Tools", slug: "asset-allocation-tools"},
        %{name: "High-Net-Worth Wealth Management", slug: "high-net-worth-wealth-management"},
        %{name: "Estate Planning", slug: "estate-planning"},
        %{name: "Tax Planning", slug: "tax-planning"},
        %{name: "Cryptocurrency Trading", slug: "cryptocurrency-trading-finance"},
        %{name: "Forex Trading", slug: "forex-trading"}
      ],
      term_meta: [%{term_key: "icon", term_value: "chart-bar"}]
    },
    %{
      name: "Business Services",
      slug: "business-services",
      subcategories: [
        %{name: "Business Consulting", slug: "business-consulting"},
        %{name: "Legal Services", slug: "legal-services"},
        %{name: "Accounting Services", slug: "accounting-services"},
        %{name: "Marketing Services", slug: "marketing-services"},
        %{name: "Business Intelligence", slug: "business-intelligence"},
        %{name: "Risk Management", slug: "risk-management"}
      ],
      term_meta: [%{term_key: "icon", term_value: "briefcase"}]
    },
    %{
      name: "Real Estate",
      slug: "real-estate",
      subcategories: [
        %{name: "Property Investment", slug: "property-investment"},
        %{name: "Real Estate Development", slug: "real-estate-development"},
        %{name: "Property Management", slug: "property-management"},
        %{name: "Real Estate Technology", slug: "real-estate-technology"},
        %{name: "Commercial Real Estate", slug: "commercial-real-estate"}
      ],
      term_meta: [%{term_key: "icon", term_value: "home"}]
    },
    %{
      name: "Digital Electronics Products",
      slug: "digital-electronics-products",
      subcategories: [
        %{name: "Consumer Electronics", slug: "consumer-electronics"},
        %{name: "Smart Devices", slug: "smart-devices"},
        %{name: "Computer Hardware", slug: "computer-hardware"},
        %{name: "Mobile Devices", slug: "mobile-devices"},
        %{name: "Gaming Hardware", slug: "gaming-hardware-electronics"},
        %{name: "Digital Accessories", slug: "digital-accessories"},
        %{name: "IoT Devices", slug: "iot-devices"}
      ],
      term_meta: [%{term_key: "icon", term_value: "camera"}]
    },
    %{
      name: "Marketing Products",
      slug: "marketing-products",
      subcategories: [
        %{name: "Digital Marketing Tools", slug: "digital-marketing-tools"},
        %{name: "Marketing Automation", slug: "marketing-automation-products"},
        %{name: "Social Media Marketing", slug: "social-media-marketing-products"},
        %{name: "Content Marketing", slug: "content-marketing-products"},
        %{name: "Email Marketing", slug: "email-marketing-products"},
        %{name: "SEO Tools", slug: "seo-tools-products"},
        %{name: "Analytics & Reporting", slug: "analytics-reporting-products"},
        %{name: "Marketing Research", slug: "marketing-research-products"}
      ],
      term_meta: [%{term_key: "icon", term_value: "megaphone"}]
    },
    %{
      name: "IT Solutions",
      slug: "it-solutions",
      subcategories: [
        %{name: "Cloud Services", slug: "cloud-services-it"},
        %{name: "Software Development", slug: "software-development"},
        %{name: "Cybersecurity", slug: "cybersecurity"},
        %{name: "Network Solutions", slug: "network-solutions"},
        %{name: "IT Infrastructure", slug: "it-infrastructure"},
        %{name: "System Integration", slug: "system-integration"},
        %{name: "IT Consulting", slug: "it-consulting"},
        %{name: "Data Management", slug: "data-management"},
        %{name: "Enterprise Software", slug: "enterprise-software"}
      ],
      term_meta: [%{term_key: "icon", term_value: "server"}]
    },
    %{
      name: "Learning & Recruitment",
      slug: "learning-recruitment",
      subcategories: [
        %{name: "Online Courses", slug: "online-courses-recruitment"},
        %{name: "Professional Certification", slug: "professional-certification-recruitment"},
        %{name: "Career Development", slug: "career-development-recruitment"},
        %{name: "Job Platforms", slug: "job-platforms"},
        %{name: "Recruitment Solutions", slug: "recruitment-solutions"},
        %{name: "Skills Assessment", slug: "skills-assessment"},
        %{name: "Corporate Training", slug: "corporate-training-recruitment"},
        %{name: "HR Management Systems", slug: "hr-management-systems"},
        %{name: "Talent Acquisition", slug: "talent-acquisition"}
      ],
      term_meta: [%{term_key: "icon", term_value: "academic-cap"}]
    },
    %{
      name: "Metaverse & Virtual Worlds",
      slug: "metaverse-virtual-worlds",
      subcategories: [
        %{name: "Virtual Real Estate", slug: "virtual-real-estate"},
        %{name: "Digital Assets", slug: "digital-assets-metaverse"},
        %{name: "Virtual Experiences", slug: "virtual-experiences"},
        %{name: "Avatar Services", slug: "avatar-services"},
        %{name: "Metaverse Infrastructure", slug: "metaverse-infrastructure"},
        %{name: "Virtual Commerce", slug: "virtual-commerce"}
      ],
      term_meta: [%{term_key: "icon", term_value: "globe"}]
    },
    %{
      name: "SaaS Solutions",
      slug: "saas-solutions",
      subcategories: [
        %{name: "Project Management", slug: "project-management-saas"},
        %{name: "CRM Software", slug: "crm-software"},
        %{name: "HR Management", slug: "hr-management-saas"},
        %{name: "Accounting Software", slug: "accounting-software"},
        %{name: "Communication Tools", slug: "communication-tools"},
        %{name: "Marketing Automation", slug: "marketing-automation-saas"},
        %{name: "Analytics Platforms", slug: "analytics-platforms"},
        %{name: "Design Software", slug: "design-software"},
        %{name: "Customer Support Software", slug: "customer-support-software"},
        %{name: "Document Management", slug: "document-management"}
      ],
      term_meta: [%{term_key: "icon", term_value: "cloud"}]
    },
    %{
      name: "Travel & Tourism",
      slug: "travel-tourism",
      subcategories: [
        %{name: "Hotels & Accommodations", slug: "hotels-accommodations"},
        %{name: "Travel Booking Platforms", slug: "travel-booking-platforms"},
        %{name: "Tour Packages", slug: "tour-packages"},
        %{name: "Adventure Tourism", slug: "adventure-tourism"},
        %{name: "Business Travel", slug: "business-travel"},
        %{name: "Travel Insurance", slug: "travel-insurance"},
        %{name: "Transportation Services", slug: "transportation-services"},
        %{name: "Travel Gear & Accessories", slug: "travel-gear-accessories"},
        %{name: "Travel Planning Tools", slug: "travel-planning-tools"}
      ],
      term_meta: [%{term_key: "icon", term_value: "airplane"}]
    },
    %{
      name: "Fashion & Lifestyle",
      slug: "fashion-lifestyle",
      subcategories: [
        %{name: "Luxury Fashion", slug: "luxury-fashion"},
        %{name: "Streetwear", slug: "streetwear"},
        %{name: "Accessories", slug: "accessories-fashion"},
        %{name: "Sustainable Fashion", slug: "sustainable-fashion"},
        %{name: "Beauty & Cosmetics", slug: "beauty-cosmetics"},
        %{name: "Fashion Technology", slug: "fashion-technology"},
        %{name: "Personal Styling", slug: "personal-styling"},
        %{name: "Fashion Marketplaces", slug: "fashion-marketplaces"}
      ],
      term_meta: [%{term_key: "icon", term_value: "shopping-bag"}]
    },
    %{
      name: "Pet Care & Services",
      slug: "pet-care-services",
      subcategories: [
        %{name: "Pet Food & Nutrition", slug: "pet-food-nutrition"},
        %{name: "Pet Healthcare", slug: "pet-healthcare"},
        %{name: "Pet Supplies", slug: "pet-supplies"},
        %{name: "Pet Training", slug: "pet-training"},
        %{name: "Pet Grooming", slug: "pet-grooming"},
        %{name: "Pet Insurance", slug: "pet-insurance"},
        %{name: "Pet Technology", slug: "pet-technology"},
        %{name: "Pet Boarding & Daycare", slug: "pet-boarding-daycare"}
      ],
      term_meta: [%{term_key: "icon", term_value: "wallet"}]
    },
    %{
      name: "Gaming & Entertainment",
      slug: "gaming-entertainment",
      subcategories: [
        %{name: "Video Games", slug: "video-games"},
        %{name: "Mobile Gaming", slug: "mobile-gaming"},
        %{name: "Gaming Hardware", slug: "gaming-hardware-entertainment"},
        %{name: "Esports", slug: "esports"},
        %{name: "Game Development", slug: "game-development"},
        %{name: "Gaming Communities", slug: "gaming-communities"},
        %{name: "Gaming Accessories", slug: "gaming-accessories"},
        %{name: "Game Streaming", slug: "game-streaming"},
        %{name: "Virtual Reality Gaming", slug: "vr-gaming"}
      ],
      term_meta: [%{term_key: "icon", term_value: "musical-note"}]
    },
    %{
      name: "Adult & Dating",
      slug: "adult-dating",
      subcategories: [
        %{name: "Dating Platforms", slug: "dating-platforms"},
        %{name: "Adult Content", slug: "adult-content"},
        %{name: "Relationship Coaching", slug: "relationship-coaching"},
        %{name: "Dating Services", slug: "dating-services"},
        %{name: "Adult Products", slug: "adult-products"}
      ],
      term_meta: [%{term_key: "icon", term_value: "heart"}]
    },
    %{
      name: "Crypto & Blockchain",
      slug: "crypto-blockchain",
      subcategories: [
        %{name: "Cryptocurrency Exchanges", slug: "cryptocurrency-exchanges"},
        %{name: "NFT Marketplaces", slug: "nft-marketplaces"},
        %{name: "DeFi Platforms", slug: "defi-platforms"},
        %{name: "Crypto Wallets", slug: "crypto-wallets"},
        %{name: "Blockchain Development", slug: "blockchain-development"},
        %{name: "Mining Equipment", slug: "mining-equipment"},
        %{name: "Crypto Trading Tools", slug: "crypto-trading-tools"}
      ],
      term_meta: [%{term_key: "icon", term_value: "currency-bangladeshi"}]
    },
    %{
      name: "Weight Loss & Fitness",
      slug: "weight-loss-fitness",
      subcategories: [
        %{name: "Diet Programs", slug: "diet-programs"},
        %{name: "Fitness Equipment", slug: "fitness-equipment"},
        %{name: "Supplements", slug: "supplements"},
        %{name: "Personal Training", slug: "personal-training"},
        %{name: "Workout Programs", slug: "workout-programs"},
        %{name: "Nutrition Planning", slug: "nutrition-planning"},
        %{name: "Fitness Apps", slug: "fitness-apps"}
      ],
      term_meta: [%{term_key: "icon", term_value: "calendar"}]
    }
  ]
}

countries = %{
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
    %{name: "Norway", slug: "norway"},
    %{name: "Malaysia", slug: "malaysia"},
    %{name: "Israel", slug: "israel"},
    %{name: "Austria", slug: "austria"},
    %{name: "Chile", slug: "chile"},
    %{name: "Philippines", slug: "philippines"},
    %{name: "Vietnam", slug: "vietnam"},
    %{name: "Finland", slug: "finland"},
    %{name: "Denmark", slug: "denmark"},
    %{name: "Romania", slug: "romania"},
    %{name: "Czech Republic", slug: "czech-republic"},
    %{name: "Portugal", slug: "portugal"},
    %{name: "Greece", slug: "greece"},
    %{name: "Ireland", slug: "ireland"},
    %{name: "New Zealand", slug: "new-zealand"},
    %{name: "Qatar", slug: "qatar"},
    %{name: "Luxembourg", slug: "luxembourg"},
    %{name: "Kuwait", slug: "kuwait"},
    %{name: "Hong Kong SAR", slug: "hong-kong-sar"},
    %{name: "Taiwan", slug: "taiwan"},
    %{name: "South Korea", slug: "south-korea"},
    %{name: "Macau SAR", slug: "macau-sar"},
    %{name: "Monaco", slug: "monaco"},
    %{name: "Liechtenstein", slug: "liechtenstein"}
  ]
}

defmodule Moly.Seed do
  require Ash.Query
  require AshPostgres.DataLayer

  def term_upsert(inputs, parent_id) when is_list(inputs) do
    Enum.map(inputs, &term_upsert(&1, parent_id))
  end

  def term_upsert(%{name: name, slug: slug} = input, parent_id) when is_map(input) do
    IO.puts("Insert name:#{name}, slug:#{slug} to table...")

    term_taxonomy =
      case parent_id do
        nil ->
          [%{taxonomy: "affiliate_category"}]

        parent_id ->
          [%{taxonomy: "affiliate_category", parent_id: parent_id}]
      end

    insert_data = %Moly.Terms.Term{name: name, slug: slug, term_taxonomy: term_taxonomy}

    insert_data =
      if Map.get(input, :term_meta),
        do: Map.put(insert_data, :term_meta, Map.get(input, :term_meta)),
        else: insert_data

    parent =
      Ash.Seed.upsert!(insert_data,
        actor: %{roles: [:admin]},
        action: :create,
        identity: :unique_slug
      )

    if Map.has_key?(input, :subcategories) do
      Map.get(input, :subcategories)
      |> term_upsert(parent.id)
    end
  end
end

Moly.Seed.term_upsert(countries, nil)
Moly.Seed.term_upsert(industries, nil)
