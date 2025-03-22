"use client"

import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";


export default function NotFound() {
  const router = useRouter();


  return (
    <div className="w-full relative overflow-y-hidden bg-white min-h-screen flex items-center justify-center  flex-col bg-[url('/404Bg.svg')] bg-no-repeat bg-cover ">
      <div className="absolute top-0 left-[50%] transform translate-x-[-50%] flex items-center justify-center flex-col max-w-[400px] ">
        <Image
          src="/404Image.svg"
          alt="image"
          height={400}
          width={400}
          className="object-cover  "
        />
        <p className=" text-2xl md:text-5xl font-bold text-center whitespace-nowrap  ">
          PAGE NOT FOUND
        </p>
      </div>

      <div className="flex flex-col md:flex-row gap-5 md:gap-10 items-center justify-center mt-[18%]  ">

        <button onClick={() => router.back()} className=" w-[200px] h-[40px] bg-gradient-to-r from-green-400 to-blue-500 rounded-3xl text-white text-base font-medium transform hover:scale-105 transition ease-in-out ">
          Go Back
        </button>


        <Link href={"/"}>
          <button className=" w-[200px] h-[40px] bg-gradient-to-r from-green-400 to-blue-500 rounded-3xl text-white text-base font-medium transform hover:scale-105 transition ease-in-out">
            Back to Home
          </button>
        </Link>
      </div>
    </div>
  );
}
