import { Router } from "express";
import { container } from "tsyringe";
import UserController from "./user.controller";
import { authenticateToken } from "../../../middleware/auth";

const router = Router();
const userController = container.resolve(UserController);

router.get("/profile", authenticateToken, userController.getProfile.bind(userController));
router.patch("/profile", authenticateToken, userController.updateProfile.bind(userController));
router.post("/claim-winnings", authenticateToken, userController.claimWinnings.bind(userController));
router.get("/claimable-amount", authenticateToken, userController.getClaimableAmount.bind(userController));
router.get("/bet-history", authenticateToken, userController.getBetHistory.bind(userController));

export default router;
