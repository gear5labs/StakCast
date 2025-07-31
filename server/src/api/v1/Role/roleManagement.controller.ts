import { Request, Response } from "express";
import { container } from "tsyringe";
import RoleInitializationService from "../../../services/roleInitialization.simple";
import ContractEventListener from "../../../services/contractEventListener";

export default class RoleManagementController {
	private roleInitService: RoleInitializationService;
	private contractEventListener: ContractEventListener;

	constructor() {
		this.roleInitService = container.resolve(RoleInitializationService);
		this.contractEventListener = container.resolve(ContractEventListener);
	}

	/**
	 * Initialize default roles for all users
	 * POST /api/v1/roles/management/init-defaults
	 */
	initializeDefaultRoles = async (req: Request, res: Response): Promise<void> => {
		try {
			await this.roleInitService.initializeDefaultRoles();

			res.status(200).json({
				message: "Default roles initialized successfully",
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to initialize default roles",
			});
		}
	};

	/**
	 * Create initial admin user
	 * POST /api/v1/roles/management/create-admin
	 */
	createInitialAdmin = async (req: Request, res: Response): Promise<void> => {
		try {
			const { adminEmail } = req.body;

			if (!adminEmail) {
				res.status(400).json({
					error: "Admin email is required",
				});
				return;
			}

			await this.roleInitService.createInitialAdmin(adminEmail);

			res.status(200).json({
				message: "Initial admin created successfully",
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to create initial admin",
			});
		}
	};

	/**
	 * Migrate existing users to role system
	 * POST /api/v1/roles/management/migrate
	 */
	migrateExistingUsers = async (req: Request, res: Response): Promise<void> => {
		try {
			await this.roleInitService.migrateExistingUsers();

			res.status(200).json({
				message: "User migration completed successfully",
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to migrate users",
			});
		}
	};

	/**
	 * Validate role system integrity
	 * GET /api/v1/roles/management/validate
	 */
	validateRoleSystem = async (req: Request, res: Response): Promise<void> => {
		try {
			const validation = await this.roleInitService.validateRoleSystemIntegrity();

			res.status(200).json({
				message: "Role system validation completed",
				data: validation,
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to validate role system",
			});
		}
	};

	/**
	 * Start contract event listener
	 * POST /api/v1/roles/management/start-listener
	 */
	startEventListener = async (req: Request, res: Response): Promise<void> => {
		try {
			await this.contractEventListener.startListening();

			res.status(200).json({
				message: "Contract event listener started",
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to start event listener",
			});
		}
	};

	/**
	 * Stop contract event listener
	 * POST /api/v1/roles/management/stop-listener
	 */
	stopEventListener = async (req: Request, res: Response): Promise<void> => {
		try {
			await this.contractEventListener.stopListening();

			res.status(200).json({
				message: "Contract event listener stopped",
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to stop event listener",
			});
		}
	};

	/**
	 * Get event listener status
	 * GET /api/v1/roles/management/listener-status
	 */
	getEventListenerStatus = async (req: Request, res: Response): Promise<void> => {
		try {
			const status = this.contractEventListener.getStatus();

			res.status(200).json({
				message: "Event listener status retrieved",
				data: status,
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to get listener status",
			});
		}
	};

	/**
	 * Sync missed contract events
	 * POST /api/v1/roles/management/sync-missed-events
	 */
	syncMissedEvents = async (req: Request, res: Response): Promise<void> => {
		try {
			const { fromBlock, toBlock } = req.body;

			if (!fromBlock) {
				res.status(400).json({
					error: "fromBlock is required",
				});
				return;
			}

			await this.contractEventListener.syncMissedEvents(fromBlock, toBlock);

			res.status(200).json({
				message: "Missed events sync completed",
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to sync missed events",
			});
		}
	};
}
