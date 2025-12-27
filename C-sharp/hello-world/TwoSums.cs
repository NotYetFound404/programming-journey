// LeetCode - Two Sums
using System;
using System.Collections;
using System.Linq.Expressions;
using System.Collections.Generic;
public class TwoSums
{
    public static void Main()
    {
        // Input
        int[] nums = { 2, 7, 11, 15 };
        int target = 9;

        // Invoke solution
        Solution solution = new Solution();
        int[] result = solution.TwoSum(nums, target);

        // Output
        Console.WriteLine($"[{result[0]}, {result[1]}]");
    }
}

// public class Solution
// {
//     public int[] TwoSum(int[] nums, int target)
//     {
//         //A = Set of int[] that has the numbers
//         //a = Set of indices related to A
//         //b = target
//         Hashtable ht = new Hashtable();
        
//         for(var i=0; i < nums.Count(); i++)
//         {
//             var X = target - nums[i];
//             if (ht.Contains(X))
//             {
//                 //var Xindex = ht[X];
//                 int Xindex = (int)ht[X]; // Unsafe if wrong type
//                 int[] answer = new int[] { Xindex, i };
//                 return answer;
//             }
//             else
//             {
//                 ht.Add(nums[i], i);
//             }
//         }
//         //int[] answer = [0,1]; // Will change this to final actual values
//         return null;
//     }
// }

public class Solution
{
    public int[] TwoSum(int[] nums, int target)
    {
        Dictionary<int, int> map = new Dictionary<int, int>();

        for (int i = 0; i < nums.Length; i++)
        {
            int complement = target - nums[i];

            if (map.TryGetValue(complement, out int index))
            {
                return new int[] { index, i };
            }

            if (!map.ContainsKey(nums[i]))
            {
                map.Add(nums[i], i);
            }
        }
        throw new System.InvalidOperationException("No valid TwoSum solution found.");
    }
}
