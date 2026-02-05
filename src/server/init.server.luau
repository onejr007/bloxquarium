-- Server Initialization with Comprehensive Integration
print("Hello world, from server!")

-- Initialize comprehensive server integration
print("Initializing comprehensive server integration with Data Reconciliation and Data Store Management...")

-- Wait for all systems to be ready with longer delay
task.wait(5)

-- Get integration status with error handling
local IntegrationManager
local success, result = pcall(function()
	IntegrationManager = require(game:GetService("ServerScriptService"):WaitForChild("IntegrationManager"))
end)

if success and IntegrationManager then
	local integrationStatus = IntegrationManager.getIntegrationStatus()
	print("Server Integration Status:", integrationStatus)

	-- Get system statistics
	local systemStats = IntegrationManager.getSystemStatistics()
	print("Server System Statistics:", systemStats)

	-- Perform manual health check
	task.spawn(function()
		task.wait(5) -- Wait for systems to stabilize
		local healthCheck = IntegrationManager.performManualHealthCheck()
		print("Server Manual Health Check Results:", healthCheck)
	end)
	
	-- Initialize Data Reconciliation monitoring
	task.spawn(function()
		task.wait(10)
		if systemStats.dataReconciliation then
			print("Data Reconciliation System: ACTIVE")
			print("  - Total Snapshots:", systemStats.dataReconciliation.totalSnapshots)
			print("  - Pending Conflicts:", systemStats.dataReconciliation.pendingConflicts)
			print("  - Resolved Conflicts:", systemStats.dataReconciliation.resolvedConflicts)
		end
	end)
	
	-- Initialize Data Store Management monitoring
	task.spawn(function()
		task.wait(10)
		if systemStats.dataStoreManager then
			print("Data Store Management System: ACTIVE")
			print("  - Total Operations:", systemStats.dataStoreManager.totalOperations)
			print("  - Success Rate:", string.format("%.1f%%", systemStats.dataStoreManager.successRate))
			print("  - Pending Backups:", systemStats.dataStoreManager.pendingBackups)
		end
	end)
	
	-- Initialize Configuration Management monitoring
	task.spawn(function()
		task.wait(10)
		if systemStats.configManager then
			print("Configuration Management System: ACTIVE")
			print("  - Version:", systemStats.configManager.configVersion)
			print("  - Last Updated:", systemStats.configManager.lastUpdated)
		end
	end)
	
	-- Initialize Configuration Bridge monitoring
	task.spawn(function()
		task.wait(10)
		if systemStats.configBridge then
			print("Configuration Bridge System: ACTIVE")
			print("  - Client-Safe Configs:", systemStats.configBridge.clientSafeConfigs)
			print("  - Shared Configs:", systemStats.configBridge.sharedConfigs)
			print("  - Total Subscriptions:", systemStats.configBridge.totalSubscriptions)
		end
	end)
	
else
	warn("IntegrationManager not available:", result)
	print("Server initialization complete with basic integration!")
end

print("Server initialization complete with comprehensive integration including Data Reconciliation and Data Store Management!")
