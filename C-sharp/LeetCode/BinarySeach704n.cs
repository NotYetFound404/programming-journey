using System;

namespace LeetCode
{
    public class BinarySeach704n
    {
        public int Search(int[] nums, int target)
    //First implementation v1
    //    Console.WriteLine("...BinarySeach704n...");
    //         // Given a sorted array (from lowest to highest)
    //         Console.WriteLine($"nums: {string.Join(",", nums)}, target: {target}");
    //         // Try to find the target in the array, if you find it return the index (position in the array)

    //         //1: How long is the array?
    //         var arrLength = nums.Length;
    //         Console.WriteLine($"Length of the arr: {arrLength}");

    //         //2: Check the extremes if a solution exists
    //         var existsSolution = false;
    //         if (nums[arrLength-1]>target && nums[0] < target)
    //         {
    //             existsSolution = true;
    //         }
    //         Console.WriteLine($"Solution is feasable?: {existsSolution}");
    //         // If not found, return -1
    //         if (!existsSolution)
    //         {
    //             return -1; //Early exit if there is no solution
    //         }
    //         //solution in the extremes (cuts constant time for larga datasets)
    //         if (nums[arrLength-1]==target) // Snips upper bound
    //         {
    //             return arrLength-1;
    //         }
    //         if (nums[0] == target) // Snips lower bound
    //         {
    //             return 0;
    //         }
    //         //Else: solution exists that is not in the extremes
    //         //Q1: Where is the "middle"
    //         //Q2: How to "move" the upper and left bounds? / Discard half the other side
    //         //Q3: When exit? Whenever both bounds are one?
    //         int currUpperBound = arrLength-2;
    //         int currLowerBound = 1;
    //         int currMidpoint = (int)(currUpperBound+currLowerBound)/2;
    //         // while (currLowerBound!=currUpperBound)
    //         // {
    //         //     currMidpoint = (int)(currUpperBound+currLowerBound)/2;
    //         //     int evalNumber = nums[currMidpoint];
    //         //     //Shrink right side to midpoint if target is less than midpoint
    //         //     if (target < evalNumber)
    //         //     {
    //         //     currUpperBound = currMidpoint;
    //         //     }
    //         //     //Expand left side to midpoint if target is more than midpoint
    //         //     if (target > evalNumber)
    //         //     {
    //         //     currLowerBound = currMidpoint;
    //         //     }
    //         // }
    //         while (currLowerBound <= currUpperBound)
    //         {
    //             currMidpoint = currLowerBound + (currUpperBound - currLowerBound) / 2;
    //             int evalNumber = nums[currMidpoint];

    //             if (evalNumber == target)
    //             {
    //                 Console.WriteLine(currMidpoint);
    //                 Console.WriteLine(nums[currMidpoint]);
    //                 return currMidpoint;
    //             }
    //             else if (target < evalNumber)
    //             {
    //                 currUpperBound = currMidpoint - 1; // move past midpoint
    //             }
    //             else
    //             {
    //                 currLowerBound = currMidpoint + 1; // move past midpoint
    //             }
    //         }

    //         return -1;

        {
        Console.WriteLine("...BinarySeach704n...");
        Console.WriteLine($"nums: {string.Join(",", nums)}, target: {target}");
        int length = nums.Length;
        Console.WriteLine($"Length of the array: {length}");
        // Guard clause: empty array
        if (length == 0)
        {
            return -1;
        }
        // Guard clause: target outside possible range
        if (target < nums[0] || target > nums[length - 1])
        {
            Console.WriteLine("Target outside array bounds");
            return -1;
        }
        // Binary search between inner bounds
        int left = 0;
        int right = length - 1;

        while (left <= right)
        {
            int mid = left + (right - left) / 2;
            int value = nums[mid];
            Console.WriteLine($"Checking index {mid}, value {value}");
            if (value == target)
            {
                Console.WriteLine($"Found target @ index {mid}");
                return mid;
            }
            if (target < value)
            {
                right = mid - 1;
            }
            else
            {
                left = mid + 1;
            }
        }
        return -1;
        }
    }
}
