//Rextester.Program.Main is the entry point for your code. Don't change it.
//Compiler version 4.0.30319.17929 for Microsoft (R) .NET Framework 4.5

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace Curse.Hashing
{
	// Token: 0x02000002 RID: 2
	public class MurmurHash2
	{
		// Token: 0x06000001 RID: 1 RVA: 0x00002050 File Offset: 0x00000250
		public static long ComputeNormalizedFileHash(string path)
		{
			return MurmurHash2.ComputeFileHash(path, true);
		}

		// Token: 0x06000002 RID: 2 RVA: 0x0000205C File Offset: 0x0000025C
		public static long ComputeFileHash(string path, bool normalizeWhitespace = false)
		{
			long result;
			using (FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read))
			{
				result = (long)((ulong)MurmurHash2.ComputeHash(stream, 0L, normalizeWhitespace));
			}
			return result;
		}

		// Token: 0x06000003 RID: 3 RVA: 0x0000209C File Offset: 0x0000029C
		public static uint ComputeHash(string input, bool normalizeWhitespace = false)
		{
			return MurmurHash2.ComputeHash(Encoding.UTF8.GetBytes(input), normalizeWhitespace);
		}

		// Token: 0x06000004 RID: 4 RVA: 0x000020AF File Offset: 0x000002AF
		public static uint ComputeHash(byte[] input, bool normalizeWhitespace = false)
		{
			return MurmurHash2.ComputeHash(new MemoryStream(input), 0L, normalizeWhitespace);
		}

		// Token: 0x06000005 RID: 5 RVA: 0x000020C0 File Offset: 0x000002C0
		public static uint ComputeHash(Stream input, long precomputedLength = 0L, bool normalizeWhitespace = false)
		{
			long length = (precomputedLength != 0L) ? precomputedLength : input.Length;
			byte[] buffer = new byte[65536];
			if (precomputedLength == 0L && normalizeWhitespace)
			{
				long position = input.Position;
				length = MurmurHash2.ComputeNormalizedLength(input, buffer);
				input.Seek(position, SeekOrigin.Begin);
			}
			uint h = (uint)(1L ^ length);
			uint i = 0u;
			int shift = 0;
			for (;;)
			{
				int bufferLength = input.Read(buffer, 0, buffer.Length);
				if (bufferLength == 0)
				{
					break;
				}
				for (int j = 0; j < bufferLength; j++)
				{
					byte b = buffer[j];
					if (!normalizeWhitespace || !MurmurHash2.IsWhitespaceCharacter(b))
					{
						i |= (uint)((uint)b << shift);
						shift += 8;
						if (shift == 32)
						{
							i *= 1540483477u;
							i ^= i >> 24;
							i *= 1540483477u;
							h *= 1540483477u;
							h ^= i;
							i = 0u;
							shift = 0;
						}
					}
				}
			}
			if (shift > 0)
			{
				h ^= i;
				h *= 1540483477u;
			}
			h ^= h >> 13;
			h *= 1540483477u;
			return h ^ h >> 15;
		}

		// Token: 0x06000006 RID: 6 RVA: 0x000021B0 File Offset: 0x000003B0
		public static uint ComputeNormalizedHash(string input)
		{
			return MurmurHash2.ComputeHash(input, true);
		}

		// Token: 0x06000007 RID: 7 RVA: 0x000021B9 File Offset: 0x000003B9
		public static uint ComputeNormalizedHash(byte[] input)
		{
			return MurmurHash2.ComputeHash(input, true);
		}

		// Token: 0x06000008 RID: 8 RVA: 0x000021C2 File Offset: 0x000003C2
		public static uint ComputeNormalizedHash(Stream input, long precomputedLength = 0L)
		{
			return MurmurHash2.ComputeHash(input, precomputedLength, true);
		}

		// Token: 0x06000009 RID: 9 RVA: 0x000021CC File Offset: 0x000003CC
		public static long ComputeNormalizedLength(Stream input, byte[] buffer = null)
		{
			long length = 0L;
			if (buffer == null)
			{
				buffer = new byte[65536];
			}
			for (;;)
			{
				int bytesRead = input.Read(buffer, 0, buffer.Length);
				if (bytesRead == 0)
				{
					break;
				}
				for (int i = 0; i < bytesRead; i++)
				{
					if (!MurmurHash2.IsWhitespaceCharacter(buffer[i]))
					{
						length += 1L;
					}
				}
			}
			return length;
		}

		// Token: 0x0600000A RID: 10 RVA: 0x00002218 File Offset: 0x00000418
		private static bool IsWhitespaceCharacter(byte b)
		{
			return b == 9 || b == 10 || b == 13 || b == 32;
		}

		// Token: 0x04000001 RID: 1
		public const int Seed = 1;

		// Token: 0x04000002 RID: 2
		public const int BufferSize = 65536;
	}
}

namespace Rextester
{
    public class Program
    {
        public static void Main(string[] args)
        {
            Console.WriteLine(Curse.Hashing.MurmurHash2.ComputeNormalizedFileHash(@"C:\Users\chara\Desktop\test.jar"));
        }
    }
}
// C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe -out:test2.exe test.cs