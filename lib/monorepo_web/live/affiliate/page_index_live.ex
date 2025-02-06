defmodule MonorepoWeb.Affiliate.PageIndexLive do
  use MonorepoWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="w-full mx-auto px-4 py-24">
      <!-- Hero Section -->
      <div class="max-w-2xl mx-auto text-center">

        <h1 class="text-5xl leading-snug font-medium mb-2">
          <span class="text-primary">Explore High-Reward</span><br/><span class="text-secondary">Unique Products</span>
        </h1>

        <h2 class="text-2xl mb-12">
          <span class="text-gray-900">stand out in a low-competition market</span>
        </h2>

        <!-- Search Bar -->
        <div class="relative">
          <div class="relative">
            <input
              type="text"
              placeholder='Explore Now and Find Your Next Opportunity!'
              class="w-full px-12 py-3 bg-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:bg-gray-50 focus:ring-green-500"
            />
            <svg class="w-5 h-5 text-gray-400 absolute left-4 top-1/2 transform -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </div>
      </div>

    </div>
    """
  end
end
