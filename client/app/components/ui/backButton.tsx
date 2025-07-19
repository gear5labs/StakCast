'use client'
import { Button } from "@/components/ui/button";
import {ArrowLeft } from "lucide-react";
import { useRouter } from "next/navigation";

export const BackButton = () => {
  const router = useRouter();
  return (
    <Button
      onClick={() => router.back()}
      variant="outline"
      className="flex items-center gap-4 !border-none cursor-pointer "
    >
      <ArrowLeft fontSize="lg" />
     Back
    </Button>
  );
};
