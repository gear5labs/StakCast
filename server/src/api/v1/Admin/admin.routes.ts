import { Router } from "express";
import { container } from "tsyringe";
import QueueController from "./queue.controller";
import { authenticateToken } from "../../../middleware/auth";

const router = Router();
const queueController = container.resolve(QueueController);

// Queue monitoring endpoints (protected)
router.get("/queue/stats", authenticateToken, queueController.getQueueStats.bind(queueController));

export default router;
