using System;
using System.IO;

namespace Curse.Hashing
{
	// Token: 0x02000002 RID: 2
	public class MurmurHash2
	{
		// Token: 0x06000005 RID: 5 RVA: 0x000020C0 File Offset: 0x000002C0
		public static ulong ComputeHash(Stream input)
		{
			byte[] buffer = new byte[65536];
			long position = input.Position;
			long length = MurmurHash2.ComputeNormalizedLength(input, buffer);
			Console.WriteLine(length);
			Console.WriteLine(position);
			input.Seek(position, SeekOrigin.Begin);
			Console.WriteLine(input.Position);
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
					if (!MurmurHash2.IsWhitespaceCharacter(b))
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
	}
}

namespace Rextester
{
    public class Program
    {
        public static void Main(string[] args)
        {
						using (FileStream stream = new FileStream(@"C:\Users\chara\Desktop\test.jar", FileMode.Open, FileAccess.Read))
						{
							Console.WriteLine(Curse.Hashing.MurmurHash2.ComputeHash(stream));
						}
        }
    }
}
// C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe -out:test2.exe test.cs