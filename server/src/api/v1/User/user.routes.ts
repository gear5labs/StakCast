import { Router } from "express";
import { container } from "tsyringe";
import UserController from "./user.controller";
import { authenticateToken } from "../../../middleware/auth";

const router = Router();
const userController = container.resolve(UserController);

router.get("/profile", authenticateToken, userController.getProfile.bind(userController));
router.patch("/profile", authenticateToken, userController.updateProfile.bind(userController));

export default router;
