// See https://aka.ms/new-console-template for more information
//Console.WriteLine("Hello, World!");
// string myVAR = "This might say something";
//Console.WriteLine("Hot reload is enabled? Sweet.");
//Console.WriteLine(myVAR);

// datatypes

// var unkownVar = "es mutable, cuidado";
// int diasEnUnMes = 30;
// char letraSola = 'b';
// string fraseCompuesta = "recibí un mensaje del asilo de viejos";
// bool ayerFueHoy = false;
// var fStringEquivalent = $"Este es el equivalente de un {unkownVar}"; 
// //Console.WriteLine(fStringEquivalent);


// string[] simpleStringArray = ["Primer objeto", "segundo", "tercero"];

// int[] simpleIntArray = [1,2,3,4];


// //para leer necesitas iterar la colección
// foreach(var ith_object in simpleStringArray)
// {
//     Console.WriteLine(ith_object);
// }

// // acceder al primer objeto de un array (ojo es zero-based indexing)
// Console.WriteLine(simpleStringArray[0]);

//Usando linq / functional sql-like statements

// string[] simpleLinQArray = ["BPrimer objeto", "segundo", "tercero", "BBB+"];
// var filteredLINQArr = simpleLinQArray.Where((e) => e.StartsWith("B"));
// foreach(var element in filteredLINQArr)
// {
//     Console.WriteLine(element);
// }

//Loops

// int[] numbers = [1,2,3,4];
// //for each (when you have an iterable collection)
// foreach(var number in numbers)
// {
//     Console.WriteLine($"foreach method: {number}");
// }
// //Standard for loop
// for(var i=10; i>=8; i--)
// {
//     Console.WriteLine($"for loop method: {i}");
// }
// //Linq foreach

// numbers.ToList().ForEach((e) => Console.WriteLine($"LINQ: {e}"));


// Comparison operators

// int algo = 10;
// Console.WriteLine(algo is bool);

// // Enums & switch:
// var currState = PlayerDoes.Jump;

// switch (currState)
// {
//     case PlayerDoes.Jump:
//         Console.WriteLine("Player jumps into the air");
//         break;

//     case PlayerDoes.Run:
//         Console.WriteLine("Player starts running");
//         break;

//     case PlayerDoes.Sleep:
//         Console.WriteLine("Player is sleeping");
//         break;
//     default:
//         Console.WriteLine("Nothing");
//         break;
// }

// var newSwitch = currState switch
// {
//     PlayerDoes.Jump => "I'm jumping high",
//     PlayerDoes.Run => "I'm running high",
//     PlayerDoes.Sleep => "I'm sleeping high",
//     _ => "Not doing Anything"   
// };
// Console.WriteLine($"From new switch: {newSwitch}");


// enum PlayerDoes
// {
//     Jump,
//     Run,
//     Sleep,
// }



// Tuples
static (int sum, int count) Analyze(int[] numbers)
{
    int sum = numbers.Sum();
    int count = numbers.Length;
    return (sum, count);
}

var analysis = Analyze([2,3]);
Console.WriteLine(analysis.sum);
Console.WriteLine(analysis.count);

var (destructuredSum, destructuredCount) = Analyze([2,3]);
Console.WriteLine(destructuredCount);
Console.WriteLine(destructuredSum);