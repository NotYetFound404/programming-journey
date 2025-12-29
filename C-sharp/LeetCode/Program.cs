using System;
using LeetCode;

namespace LeetCodeApp
{
    class Program
    {
        static void Main()
        {
            var curProblem = new BinarySeach704n();
            //curProblem.Search(nums: new int[] {-1,0,3,5,9,12}, target: 9);
            curProblem.Search(nums: new int[] {5}, target: 5);
            Console.WriteLine("End of program");
        }
    }
}
