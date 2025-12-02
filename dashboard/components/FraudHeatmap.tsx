export function FraudHeatmap() {
    return (
        <div className="bg-gray-800 rounded-xl border border-gray-700 p-4 h-[400px] flex items-center justify-center">
            <div className="text-center">
                <h3 className="text-lg font-semibold text-white mb-2">Fraud Heatmap</h3>
                <p className="text-gray-400">
                    (Map integration placeholder - requires Google Maps API key)
                </p>
                <div className="mt-4 w-64 h-64 bg-gray-700 rounded-full mx-auto flex items-center justify-center animate-pulse">
                    <span className="text-xs text-gray-500">Map View</span>
                </div>
            </div>
        </div>
    )
}
