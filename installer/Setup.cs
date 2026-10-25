// Instalador de Path Overflow (lo compila tools/build_release.ps1 con el csc de
// .NET Framework, que viene con Windows). Lleva dentro el juego y el desinstalador
// como recursos. Instala solo para el usuario, sin pedir administrador:
//   %LOCALAPPDATA%\Programs\PathOverflow\PathOverflow.exe (+ uninstall.ps1)
//   accesos directos en el menú Inicio y el escritorio, y «Desinstalar Path Overflow»
// Las partidas guardadas (%APPDATA%\Godot\app_userdata\Path Overflow) no se tocan.
// «PathOverflow-Setup.exe /extraer carpeta» solo saca los archivos (para probarlo).
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

static class Setup
{
	static readonly string[] Files = { "PathOverflow.exe", "uninstall.ps1" };

	[STAThread]
	static int Main(string[] args)
	{
		if (args.Length == 2 && args[0] == "/extraer")
		{
			Extract(args[1]);
			return 0;
		}
		string target = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"Programs\PathOverflow");
		if (MessageBox.Show("¿Instalar Path Overflow en\n" + target + "?\n\nTus partidas guardadas no se tocan.", "Path Overflow",
			MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes)
			return 1;
		try
		{
			Extract(target);
			string game = Path.Combine(target, "PathOverflow.exe");
			string menu = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "Path Overflow");
			Directory.CreateDirectory(menu);
			Shortcut(Path.Combine(menu, "Path Overflow.lnk"), game, "", target);
			Shortcut(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), "Path Overflow.lnk"), game, "", target);
			Shortcut(Path.Combine(menu, "Desinstalar Path Overflow.lnk"), "powershell.exe",
				"-ExecutionPolicy Bypass -File \"" + Path.Combine(target, "uninstall.ps1") + "\"", target);
			MessageBox.Show("Path Overflow quedó instalado. Lo tienes en el escritorio y en el menú Inicio.", "Path Overflow");
			Process.Start(new ProcessStartInfo(game) { WorkingDirectory = target });
			return 0;
		}
		catch (Exception e)
		{
			MessageBox.Show("No se pudo instalar: " + e.Message, "Path Overflow", MessageBoxButtons.OK, MessageBoxIcon.Error);
			return 2;
		}
	}

	// Saca los archivos que lleva dentro a la carpeta.
	static void Extract(string dir)
	{
		Directory.CreateDirectory(dir);
		Assembly me = Assembly.GetExecutingAssembly();
		foreach (string name in Files)
		{
			using (Stream src = me.GetManifestResourceStream(name))
			using (FileStream dst = File.Create(Path.Combine(dir, name)))
				src.CopyTo(dst);
		}
	}

	// Acceso directo con WScript.Shell (por reflexión, sin referencias COM extra).
	static void Shortcut(string path, string exe, string arguments, string workdir)
	{
		Type shellType = Type.GetTypeFromProgID("WScript.Shell");
		object shell = Activator.CreateInstance(shellType);
		object link = shellType.InvokeMember("CreateShortcut", BindingFlags.InvokeMethod, null, shell, new object[] { path });
		Type linkType = link.GetType();
		linkType.InvokeMember("TargetPath", BindingFlags.SetProperty, null, link, new object[] { exe });
		linkType.InvokeMember("Arguments", BindingFlags.SetProperty, null, link, new object[] { arguments });
		linkType.InvokeMember("WorkingDirectory", BindingFlags.SetProperty, null, link, new object[] { workdir });
		linkType.InvokeMember("Save", BindingFlags.InvokeMethod, null, link, null);
	}
}
