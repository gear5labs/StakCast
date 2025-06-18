import { Router } from "express";
import { container } from "tsyringe";
import AuthController from "./auth.controller";
import { authenticateToken } from "../../../middleware/auth";

const router = Router();
const authController = container.resolve(AuthController);

router.post("/register", authController.register.bind(authController));
router.post("/login", authController.login.bind(authController));
router.post("/refresh", authController.refreshToken.bind(authController));
router.post("/logout", authenticateToken, authController.logout.bind(authController));

export default router; 