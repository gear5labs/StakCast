import React, { useState } from "react";
import { X, AlertTriangle } from "lucide-react";
import Modal from "./Modal";
import { useCreateMarket, CreateMarketParams } from "../../hooks/useCreateMarket";
import { toast } from "react-toastify";

interface CreateMarketModalProps {
  isOpen: boolean;
  onClose: () => void;
  closeOnOverlayClick?: boolean;
  closeOnEsc?: boolean;
}

const CreateMarketModal: React.FC<CreateMarketModalProps> = ({ isOpen, onClose, closeOnOverlayClick = true, closeOnEsc = true }) => {
  const { createMarket, loading } = useCreateMarket();

  const [formData, setFormData] = useState({
    title: "",
    description: "",
    choice1: "",
    choice2: "",
    category: 0,
    endDate: "",
    endTime: "",
    predictionMarketType: 0,
    cryptoAsset: "BTC",
    targetPrice: 0,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  const categories = [
    { value: 0, label: "Normal" },
    { value: 1, label: "Politics" },
    { value: 2, label: "Sports" },
    { value: 3, label: "Crypto" },
    { value: 4, label: "Business" },
    { value: 5, label: "Entertainment" },
    { value: 6, label: "Science" },
    { value: 7, label: "Other" },
  ];

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.title.trim()) {
      newErrors.title = "Title is required";
    }

    if (!formData.description.trim()) {
      newErrors.description = "Description is required";
    }

    if (!formData.choice1.trim()) {
      newErrors.choice1 = "First choice is required";
    }

    if (!formData.choice2.trim()) {
      newErrors.choice2 = "Second choice is required";
    }

    if (formData.choice1.trim() === formData.choice2.trim()) {
      newErrors.choice2 = "Choices must be different";
    }

    if (!formData.endDate) {
      newErrors.endDate = "End date is required";
    }

    if (!formData.endTime) {
      newErrors.endTime = "End time is required";
    }

    if (formData.endDate && formData.endTime) {
      const endDateTime = new Date(`${formData.endDate}T${formData.endTime}`);
      if (endDateTime <= new Date()) {
        newErrors.endDate = "End date must be in the future";
      }
    }

    // Validate crypto fields if market type is crypto
    if (formData.predictionMarketType === 1) {
      if (!formData.targetPrice || formData.targetPrice <= 0) {
        newErrors.targetPrice = "Target price is required and must be greater than 0";
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    const endDateTime = new Date(`${formData.endDate}T${formData.endTime}`);
    const endTimeUnix = Math.floor(endDateTime.getTime() / 1000);

    const params: CreateMarketParams = {
      title: formData.title.trim(),
      description: formData.description.trim(),
      choices: [formData.choice1.trim(), formData.choice2.trim()],
      category: formData.category,
      endTime: endTimeUnix,
      predictionMarketType: formData.predictionMarketType,
      cryptoAsset: formData.predictionMarketType === 1 ? formData.cryptoAsset : undefined,
      targetPrice: formData.predictionMarketType === 1 ? formData.targetPrice : undefined,
    };

    try {
      await createMarket(params);
      // Reset form and close modal on success
      setFormData({
        title: "",
        description: "",
        choice1: "",
        choice2: "",
        category: 0,
        endDate: "",
        endTime: "",
        predictionMarketType: 0,
        cryptoAsset: "BTC",
        targetPrice: 0,
      });
      setErrors({});
      onClose();
    } catch (error) {
      console.error("Failed to create market:", error);
      toast.error(
        typeof error === "string" ? error : "Failed to initiate market creation"
      );
    }
  };

  const handleInputChange = (field: string, value: string | number) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: "" }));
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} closeOnOverlayClick={closeOnOverlayClick} closeOnEsc={closeOnEsc}>
      <div className="w-full max-w-2xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold bg-gradient-to-r from-slate-900 to-slate-600 dark:from-white dark:to-slate-300 bg-clip-text text-transparent">
            Create Market
          </h2>
          <button
            onClick={onClose}
            className="flex items-center justify-center w-8 h-8 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
          >
            <X className="w-4 h-4 text-slate-600 dark:text-slate-400" />
          </button>
        </div>

        {/* Disclaimer */}
        <div className="flex items-start gap-3 p-4 mb-6 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-xl">
          <AlertTriangle className="w-5 h-5 text-amber-600 dark:text-amber-400 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-medium text-amber-800 dark:text-amber-200">
              Moderator Access Required
            </p>
            <p className="text-sm text-amber-700 dark:text-amber-300 mt-1">
              Only moderators can create markets at this time. If you&apos;re not a moderator, this transaction will fail.
            </p>
          </div>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Title */}
          <div>
            <label className="block text-sm font-medium text-slate-900 dark:text-white mb-2">
              Market Title
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => handleInputChange("title", e.target.value)}
              className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-500 dark:placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Enter market title..."
            />
            {errors.title && (
              <p className="text-sm text-red-600 dark:text-red-400 mt-1">{errors.title}</p>
            )}
          </div>

          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-slate-900 dark:text-white mb-2">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => handleInputChange("description", e.target.value)}
              rows={3}
              className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-500 dark:placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
              placeholder="Describe the market..."
            />
            {errors.description && (
              <p className="text-sm text-red-600 dark:text-red-400 mt-1">{errors.description}</p>
            )}
          </div>

          {/* Choices */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-900 dark:text-white mb-2">
                Choice 1
              </label>
              <input
                type="text"
                value={formData.choice1}
                onChange={(e) => handleInputChange("choice1", e.target.value)}
                className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-500 dark:placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="e.g., Yes"
              />
              {errors.choice1 && (
                <p className="text-sm text-red-600 dark:text-red-400 mt-1">{errors.choice1}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-900 dark:text-white mb-2">
                Choice 2
              </label>
              <input
                type="text"
                value={formData.choice2}
                onChange={(e) => handleInputChange("choice2", e.target.value)}
                className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-500 dark:placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="e.g., No"
              />
              {errors.choice2 && (
                <p className="text-sm text-red-600 dark:text-red-400 mt-1">{errors.choice2}</p>
              )}
            </div>
          </div>

          {/* Category */}
          <div>
            <label className="block text-sm font-medium text-slate-900 dark:text-white mb-2">
              Category
            </label>
            <select
              value={formData.category}
              onChange={(e) => handleInputChange("category", parseInt(e.target.value))}
              className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              {categories.map((cat) => (
                <option key={cat.value} value={cat.value}>
                  {cat.label}
                </option>
              ))}
            </select>
          </div>

          {/* End Date and Time */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-900 dark:text-white mb-2">
                End Date
              </label>
              <input
                type="date"
                value={formData.endDate}
                onChange={(e) => handleInputChange("endDate", e.target.value)}
                min={new Date().toISOString().split('T')[0]}
                className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              {errors.endDate && (
                <p className="text-sm text-red-600 dark:text-red-400 mt-1">{errors.endDate}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-900 dark:text-white mb-2">
                End Time
              </label>
              <input
                type="time"
                value={formData.endTime}
                onChange={(e) => handleInputChange("endTime", e.target.value)}
                className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              {errors.endTime && (
                <p className="text-sm text-red-600 dark:text-red-400 mt-1">{errors.endTime}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-900 dark:text-white mb-2">
                Market Type
              </label>
              <select
                value={formData.predictionMarketType}
                onChange={(e) => handleInputChange("predictionMarketType", parseInt(e.target.value))}
                className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value={0}>Non-Crypto</option>
                <option value={1}>Crypto</option>
              </select>
            </div>

            {/* Crypto Fields - Only show when market type is crypto */}
            {formData.predictionMarketType === 1 && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-900 dark:text-white mb-2">
                    Crypto Asset
                  </label>
                  <select
                    value={formData.cryptoAsset}
                    onChange={(e) => handleInputChange("cryptoAsset", e.target.value)}
                    className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="BTC">BTC</option>
                    <option value="ETH">ETH</option>
                    <option value="STRK">STRK</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-900 dark:text-white mb-2">
                    Target Price
                  </label>
                  <input
                    type="number"
                    min={0}
                    step="0.01"
                    value={formData.targetPrice}
                    onChange={(e) => handleInputChange("targetPrice", e.target.value)}
                    className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-500 dark:placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="e.g., 3000"
                  />
                  {errors.targetPrice && (
                    <p className="text-sm text-red-600 dark:text-red-400 mt-1">{errors.targetPrice}</p>
                  )}
                </div>
              </div>
            )}
          </div>

          {/* Submit Button */}
          <div className="flex gap-4 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-6 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 font-medium hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 px-6 py-3 rounded-xl bg-gradient-to-r from-blue-600 to-purple-600 text-white font-medium hover:from-blue-700 hover:to-purple-700 transition-all shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? "Creating..." : "Create Market"}
            </button>
          </div>
        </form>
      </div>
    </Modal>
  );
};

export default CreateMarketModal; 