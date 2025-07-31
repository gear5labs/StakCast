#!/usr/bin/env ts-node

import "reflect-metadata";
import { container } from "tsyringe";
import RoleService from "./src/api/v1/Role/role.service.simple";
import RoleInitializationService from "./src/services/roleInitialization.simple";
import { UserRole } from "./src/api/v1/Role/role.types";

async function runRoleInitialization() {
	try {
		console.log("🚀 Starting role system initialization...");

		// Register services in container
		container.registerSingleton(RoleService);
		container.registerSingleton(RoleInitializationService);

		// Get role service instance
		const roleService = container.resolve(RoleService);
		const initService = container.resolve(RoleInitializationService);

		console.log("✅ Services initialized successfully");

		// Test role assignment
		console.log("\n📝 Testing role assignment...");

		const testUser = "test-user-123";
		await roleService.assignRole({
			userId: testUser,
			role: UserRole.USER,
			assignedBy: "initialization-script",
		});

		console.log(`✅ Assigned USER role to ${testUser}`);

		// Test role retrieval
		const userRoles = await roleService.getUserRoles(testUser);
		console.log(`📋 User roles: ${JSON.stringify(userRoles, null, 2)}`);

		// Test role checking
		const hasUserRole = await roleService.hasRole(testUser, UserRole.USER);
		const hasAdminRole = await roleService.hasRole(testUser, UserRole.ADMIN);

		console.log(`🔍 Has USER role: ${hasUserRole}`);
		console.log(`🔍 Has ADMIN role: ${hasAdminRole}`);

		// Test role query
		const allRoles = await roleService.queryRoles({});
		console.log(`📊 Total roles in system: ${allRoles.length}`);

		// Test statistics
		const stats = await roleService.getRoleStats();
		console.log(`📈 Role statistics: ${JSON.stringify(stats, null, 2)}`);

		// Initialize default roles using the service
		console.log("\n🔧 Running default role initialization...");
		await initService.initializeDefaultRoles();

		// Final statistics
		const finalStats = await roleService.getRoleStats();
		console.log(`📊 Final role statistics: ${JSON.stringify(finalStats, null, 2)}`);

		console.log("\n✅ Role system initialization completed successfully!");
		console.log("🎉 All role management components are working correctly!");
	} catch (error: any) {
		console.error("❌ Role initialization failed:", error.message);
		console.error("Stack trace:", error.stack);
		process.exit(1);
	}
}

// Run the initialization
runRoleInitialization()
	.then(() => {
		console.log("\n🏁 Script execution completed");
		process.exit(0);
	})
	.catch(error => {
		console.error("❌ Script execution failed:", error);
		process.exit(1);
	});
