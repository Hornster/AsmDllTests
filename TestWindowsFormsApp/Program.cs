using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace TestWindowsFormsApp
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [DllImport(@"C:\Users\karol\source\repos\AsmDllTests\Debug\CDllTests.dll", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
        static extern int callFoo();
        [STAThread]
        static void Main()
        {
            int data = callFoo();
            Console.WriteLine("The numbah's: " + data);
            /*Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new Form1());*/
            Console.Read();
        }
    }
}
