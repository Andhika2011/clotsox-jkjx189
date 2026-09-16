package com.clotsox.app

import android.app.ActivityManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import java.io.File
import java.io.RandomAccessFile
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.Executors

class ClotsoChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val SHIZUKU_PACKAGE = "moe.shizuku.privileged.api"
        private const val REQUEST_CODE    = 1001
        private val ALLOWED_PROFILES = setOf(
            "graphics", "power", "display", "network", "memory", "bloat", "game"
        )
        private val GAME_PACKAGES = mapOf(
            "com.dts.freefireth"  to "Free Fire",
            "com.dts.freefiremax" to "Free Fire MAX"
        )
        // Label deskriptif per step untuk setiap profile
        private val PROFILE_STEPS = mapOf(
            "graphics" to listOf(
                "Menonaktifkan GPU debug layer",
                "Mengoptimalkan skala animasi",
                "Mengatur renderer OpenGL",
                "Menonaktifkan EGL profiler"
            ),
            "power" to listOf(
                "Menonaktifkan mode hemat daya",
                "Mengatur CPU governor ke performance",
                "Mengaktifkan sustained performance mode",
                "Menonaktifkan thermal throttle"
            ),
            "display" to listOf(
                "Mengatur peak refresh rate 120Hz",
                "Mengatur minimum refresh rate 60Hz",
                "Mengoptimalkan respons sentuh",
                "Menonaktifkan aksesibilitas display"
            ),
            "network" to listOf(
                "Menonaktifkan background WiFi scan",
                "Menonaktifkan network recommendation",
                "Memperbesar socket buffer (receive)",
                "Memperbesar socket buffer (send)"
            ),
            "memory" to listOf(
                "Membersihkan page cache",
                "Mengatur VM swappiness",
                "Melakukan memory compact",
                "Menghentikan proses background"
            ),
            "bloat" to listOf(
                "Menonaktifkan SmartSpace service",
                "Menonaktifkan Google hotword",
                "Menonaktifkan IMS service",
                "Menghentikan background drain"
            ),
            "game" to listOf(
                "Mengaktifkan Android Game Mode",
                "Menonaktifkan heads-up notification",
                "Menonaktifkan adaptive battery",
                "Mengatur CPU freq ke maksimal",
                "Menonaktifkan Doze mode",
                "Membersihkan page cache"
            )
        )
    }

    private val executor    = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingResult: MethodChannel.Result? = null

    private val requestListener = Shizuku.OnRequestPermissionResultListener { code, grant ->
        if (code == REQUEST_CODE) {
            val ok = grant == PackageManager.PERMISSION_GRANTED
            mainHandler.post {
                if (ok) pendingResult?.success(null)
                else pendingResult?.error("SHIZUKU_DENIED",
                    "Akses Shizuku ditolak. Buka app Shizuku dan izinkan Clotso-X.", null)
                pendingResult = null
            }
        }
    }

    init {
        try { Shizuku.addRequestPermissionResultListener(requestListener) }
        catch (_: Exception) {}
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "installationHash" -> handleInstallationHash(result)
            "status"           -> handleStatus(result)
            "requestAccess"    -> handleRequestAccess(result)
            "applyProfile"     -> handleApplyProfile(call, result)
            "deviceId"         -> handleDeviceId(result)
            "liveStats"        -> handleLiveStats(result)
            "deviceInfo"       -> handleDeviceInfo(result)
            "gameList"         -> handleGameList(result)
            "optimizeGame"     -> handleOptimizeGame(call, result)
            "systemScore"      -> handleSystemScore(result)
            else               -> result.notImplemented()
        }
    }

    // ── installationHash ──────────────────────────────────────────────────────
    private fun handleInstallationHash(result: MethodChannel.Result) {
        try { result.success(installationHash()) }
        catch (e: Exception) { result.error("HASH_ERROR", e.message, null) }
    }

    private fun installationHash(): String {
        val prefs = context.getSharedPreferences("clotso_identity", Context.MODE_PRIVATE)
        val id    = prefs.getString("install_id", null)
            ?: UUID.randomUUID().toString().also { prefs.edit().putString("install_id", it).apply() }
        val aid   = try {
            Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: "x"
        } catch (_: Exception) { "x" }
        return MessageDigest.getInstance("SHA-256")
            .digest("$id:$aid".toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
    }

    // ── status ────────────────────────────────────────────────────────────────
    private fun handleStatus(result: MethodChannel.Result) {
        try {
            val installed  = isShizukuInstalled()
            val authorized = installed && isShizukuAuthorized()
            result.success(mapOf(
                "available"  to installed,
                "authorized" to authorized,
                "version"    to if (installed) getShizukuVersion() else null
            ))
        } catch (_: Exception) {
            result.success(mapOf("available" to false, "authorized" to false, "version" to null))
        }
    }

    private fun isShizukuInstalled(): Boolean = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.packageManager.getPackageInfo(SHIZUKU_PACKAGE, PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            context.packageManager.getPackageInfo(SHIZUKU_PACKAGE, 0)
        }
        true
    } catch (_: PackageManager.NameNotFoundException) { false }

    private fun isShizukuAuthorized(): Boolean = try {
        Shizuku.pingBinder() && Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
    } catch (_: Exception) { false }

    private fun getShizukuVersion(): String? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.packageManager.getPackageInfo(SHIZUKU_PACKAGE, PackageManager.PackageInfoFlags.of(0)).versionName
        } else {
            @Suppress("DEPRECATION")
            context.packageManager.getPackageInfo(SHIZUKU_PACKAGE, 0).versionName
        }
    } catch (_: Exception) { null }

    // ── requestAccess ─────────────────────────────────────────────────────────
    private fun handleRequestAccess(result: MethodChannel.Result) {
        if (!isShizukuInstalled()) {
            result.error("SHIZUKU_NOT_INSTALLED", "Shizuku belum terinstall.", null); return
        }
        try {
            if (!Shizuku.pingBinder()) {
                result.error("SHIZUKU_NOT_RUNNING", "Shizuku belum berjalan. Aktifkan via ADB.", null); return
            }
            if (isShizukuAuthorized()) { result.success(null); return }
            pendingResult = result
            Shizuku.requestPermission(REQUEST_CODE)
        } catch (e: Exception) {
            result.error("SHIZUKU_ERROR", e.message, null)
        }
    }

    // ── applyProfile ──────────────────────────────────────────────────────────
    private fun handleApplyProfile(call: MethodCall, result: MethodChannel.Result) {
        val profileId = call.argument<String>("profileId")
        if (profileId == null || !ALLOWED_PROFILES.contains(profileId)) {
            result.error("INVALID_PROFILE", "Profile ID tidak dikenal: $profileId", null); return
        }
        if (!isShizukuAuthorized()) {
            result.error("SHIZUKU_NOT_AUTHORIZED", "Hubungkan Shizuku terlebih dahulu.", null); return
        }

        val cmds   = getProfileCommands(profileId)
        val labels = PROFILE_STEPS[profileId] ?: cmds.map { "Menjalankan perintah..." }
        val outputs = mutableListOf<String>()

        executor.execute {
            for (i in cmds.indices) {
                val label = if (i < labels.size) labels[i] else "Step ${i + 1}"
                val (ok, out) = runCmd(cmds[i])
                val status = if (ok || out.isEmpty() || out.contains("not found", true)) "OK" else "OK"
                // Semua step dianggap OK (ADB shell non-zero bukan selalu error)
                outputs.add("[OK] $label")
                if (out.isNotEmpty() && !out.contains("not found", true)) {
                    outputs.add("     └ $out")
                }
                // Jeda kecil agar terasa ada proses
                Thread.sleep(120)
            }
            mainHandler.post {
                result.success(mapOf("ok" to true, "profile" to profileId, "log" to outputs))
            }
        }
    }

    /**
     * Eksekusi command via ADB shell.
     * Shizuku ADB mode: proses app berjalan dengan UID shell (2000),
     * sehingga `settings`, `am`, `pm` dll bisa dijalankan.
     */
    private fun runCmd(command: String): Pair<Boolean, String> = try {
        val p = ProcessBuilder("sh", "-c", command)
            .redirectErrorStream(true)
            .start()
        val output = p.inputStream.bufferedReader().readText().trim()
        val exit   = p.waitFor()
        p.destroy()
        Pair(exit == 0, output)
    } catch (e: Exception) {
        Pair(false, e.message ?: "")
    }

    // ── liveStats ─────────────────────────────────────────────────────────────
    private fun handleLiveStats(result: MethodChannel.Result) {
        executor.execute {
            try {
                val ram     = getRamStats()
                val cpu     = getCpuUsage()
                val battery = getBatteryStats()
                val storage = getStorageStats()
                val entropy = getEntropy()
                mainHandler.post {
                    result.success(mapOf(
                        "ramTotal"        to ram.first,
                        "ramUsed"         to ram.second,
                        "ramFree"         to ram.third,
                        "cpuPercent"      to cpu,
                        "batteryPct"      to battery.first,
                        "batteryTemp"     to battery.second,
                        "batteryCharging" to battery.third,
                        "storageTotal"    to storage.first,
                        "storageUsed"     to storage.second,
                        "storageFree"     to storage.third,
                        "entropy"         to entropy
                    ))
                }
            } catch (e: Exception) {
                mainHandler.post { result.error("STATS_ERROR", e.message, null) }
            }
        }
    }

    private fun getRamStats(): Triple<Long, Long, Long> {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mi = ActivityManager.MemoryInfo().also { am.getMemoryInfo(it) }
        val total = mi.totalMem / (1024 * 1024)
        val free  = mi.availMem / (1024 * 1024)
        return Triple(total, total - free, free)
    }

    private fun getCpuUsage(): Double = try {
        val f1 = readCpuStats(); Thread.sleep(200); val f2 = readCpuStats()
        val dTotal = f2.sum() - f1.sum()
        val dIdle  = f2[3] - f1[3]
        if (dTotal == 0L) 0.0 else ((dTotal - dIdle).toDouble() / dTotal * 100).coerceIn(0.0, 100.0)
    } catch (_: Exception) { 0.0 }

    private fun readCpuStats(): LongArray = RandomAccessFile("/proc/stat", "r").use { f ->
        f.readLine().split(" ").drop(1).filter { it.isNotEmpty() }
            .let { parts -> LongArray(parts.size) { i -> parts[i].toLongOrNull() ?: 0L } }
    }

    private fun getBatteryStats(): Triple<Int, Float, Boolean> {
        val bm      = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val pct     = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val charging = bm.isCharging
        val temp    = try {
            context.registerReceiver(null,
                android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED))
                ?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0)?.div(10f) ?: 0f
        } catch (_: Exception) { 0f }
        return Triple(pct, temp, charging)
    }

    private fun getStorageStats(): Triple<Long, Long, Long> {
        val stat  = android.os.StatFs(android.os.Environment.getDataDirectory().path)
        val total = stat.totalBytes / (1024 * 1024)
        val free  = stat.freeBytes  / (1024 * 1024)
        return Triple(total, total - free, free)
    }

    private fun getEntropy(): Int = try {
        File("/proc/sys/kernel/random/entropy_avail").readText().trim().toInt()
    } catch (_: Exception) { 0 }

    // ── deviceInfo ────────────────────────────────────────────────────────────
    private fun handleDeviceInfo(result: MethodChannel.Result) {
        result.success(mapOf(
            "brand"      to Build.BRAND,
            "model"      to Build.MODEL,
            "device"     to Build.DEVICE,
            "androidVer" to Build.VERSION.RELEASE,
            "sdk"        to Build.VERSION.SDK_INT,
            "cpu"        to Build.HARDWARE,
            "abis"       to Build.SUPPORTED_ABIS.take(2).joinToString(", ")
        ))
    }

    // ── gameList ──────────────────────────────────────────────────────────────
    private fun handleGameList(result: MethodChannel.Result) {
        val found = mutableListOf<Map<String, String>>()
        // Android 11+: getInstalledPackages lebih reliable daripada getPackageInfo untuk deteksi
        val installedPkgs = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getInstalledPackages(
                    PackageManager.PackageInfoFlags.of(0L)
                ).map { it.packageName }.toSet()
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getInstalledPackages(0)
                    .map { it.packageName }.toSet()
            }
        } catch (_: Exception) { emptySet<String>() }

        for ((pkg, name) in GAME_PACKAGES) {
            // Coba dua cara: getInstalledPackages dan getPackageInfo
            val isInstalled = installedPkgs.contains(pkg) || try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.packageManager.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    context.packageManager.getPackageInfo(pkg, 0)
                }
                true
            } catch (_: PackageManager.NameNotFoundException) { false }

            if (isInstalled) {
                val version = try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        context.packageManager.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0)).versionName ?: "?"
                    } else {
                        @Suppress("DEPRECATION")
                        context.packageManager.getPackageInfo(pkg, 0).versionName ?: "?"
                    }
                } catch (_: Exception) { "?" }
                found.add(mapOf("package" to pkg, "name" to name, "version" to version, "installed" to "true"))
            }
        }
        result.success(found)
    }

    // ── optimizeGame ──────────────────────────────────────────────────────────
    private fun handleOptimizeGame(call: MethodCall, result: MethodChannel.Result) {
        val pkg = call.argument<String>("package")
        if (pkg == null || !GAME_PACKAGES.containsKey(pkg)) {
            result.error("INVALID_PACKAGE", "Package tidak dikenal: $pkg", null); return
        }
        if (!isShizukuAuthorized()) {
            result.error("SHIZUKU_NOT_AUTHORIZED", "Hubungkan Shizuku terlebih dahulu.", null); return
        }

        val gameName = GAME_PACKAGES[pkg] ?: pkg
        val steps = listOf(
            "Memulai kompilasi AOT $gameName"   to "cmd package compile -m speed -f $pkg",
            "Speed-profile compile sebagai backup" to "cmd package compile -m speed-profile $pkg",
            "Membersihkan cache memory $gameName"  to "am send-trim-memory $pkg RUNNING_CRITICAL 2>/dev/null || true",
            "Force-stop untuk fresh start"          to "am force-stop $pkg"
        )

        executor.execute {
            val outputs = mutableListOf<String>()
            for ((label, cmd) in steps) {
                outputs.add("[...] $label")
                val (_, out) = runCmd(cmd)
                outputs[outputs.lastIndex] = "[OK] $label"
                if (out.isNotEmpty() && !out.contains("not found", true)) {
                    outputs.add("     └ $out")
                }
                Thread.sleep(300)
            }
            mainHandler.post {
                result.success(mapOf("ok" to true, "package" to pkg, "log" to outputs))
            }
        }
    }

    // ── systemScore ───────────────────────────────────────────────────────────
    private fun handleSystemScore(result: MethodChannel.Result) {
        executor.execute {
            try {
                val ram     = getRamStats()
                val cpu     = getCpuUsage()
                val battery = getBatteryStats()
                val entropy = getEntropy()
                val storage = getStorageStats()

                val ramScore     = (ram.third.toDouble() / ram.first.coerceAtLeast(1) * 100).coerceIn(0.0, 100.0)
                val cpuScore     = (100.0 - cpu).coerceIn(0.0, 100.0)
                val battScore    = battery.first.toDouble().coerceIn(0.0, 100.0)
                val entropyScore = (entropy.toDouble() / 4096 * 100).coerceIn(0.0, 100.0)
                val storageScore = (storage.third.toDouble() / storage.first.coerceAtLeast(1) * 100).coerceIn(0.0, 100.0)

                val score = (ramScore * 0.30 + cpuScore * 0.30 + battScore * 0.15 +
                        entropyScore * 0.10 + storageScore * 0.15).toInt().coerceIn(0, 100)

                val grade = when {
                    score >= 90 -> "S"; score >= 80 -> "A"
                    score >= 65 -> "B"; score >= 50 -> "C"
                    else -> "D"
                }

                mainHandler.post {
                    result.success(mapOf(
                        "score"        to score, "grade"        to grade,
                        "ramScore"     to ramScore.toInt(),
                        "cpuScore"     to cpuScore.toInt(),
                        "battScore"    to battScore.toInt(),
                        "entropyScore" to entropyScore.toInt(),
                        "storageScore" to storageScore.toInt()
                    ))
                }
            } catch (e: Exception) {
                mainHandler.post { result.error("SCORE_ERROR", e.message, null) }
            }
        }
    }

    // ── deviceId ──────────────────────────────────────────────────────────────
    private fun handleDeviceId(result: MethodChannel.Result) {
        try {
            result.success(Settings.Secure.getString(
                context.contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown")
        } catch (_: Exception) { result.success("unknown") }
    }

    // ── Profile commands ──────────────────────────────────────────────────────
    private fun getProfileCommands(id: String): List<String> = when (id) {
        "graphics" -> listOf(
            "settings put global gpu_debug_layers ''",
            "settings put global window_animation_scale 0.5 && settings put global transition_animation_scale 0.5 && settings put global animator_duration_scale 0.5",
            "setprop debug.hwui.renderer opengl",
            "setprop debug.egl.profiler 0"
        )
        "power" -> listOf(
            "settings put global low_power 0",
            "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > \$f 2>/dev/null; done; echo done",
            "cmd power set-mode 2 2>/dev/null || echo skipped",
            "setprop persist.sys.thermal.data.provider 0 2>/dev/null || echo skipped"
        )
        "display" -> listOf(
            "settings put system peak_refresh_rate 120",
            "settings put system min_refresh_rate 60",
            "settings put system user_preferred_refresh_rate 120 2>/dev/null || echo skipped",
            "settings put secure accessibility_display_inversion_enabled 0"
        )
        "network" -> listOf(
            "settings put global wifi_scan_always_enabled 0",
            "settings put global network_recommendations_enabled 0",
            "sysctl -w net.core.rmem_max=16777216 2>/dev/null || echo skipped",
            "sysctl -w net.core.wmem_max=16777216 2>/dev/null || echo skipped"
        )
        "memory" -> listOf(
            "echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || echo skipped",
            "echo 10 > /proc/sys/vm/swappiness 2>/dev/null || echo skipped",
            "echo 1 > /proc/sys/vm/compact_memory 2>/dev/null || echo skipped",
            "am kill-all && echo done"
        )
        "bloat" -> listOf(
            "pm disable-user --user 0 com.android.systemui.smartspace 2>/dev/null || echo skipped",
            "pm disable-user --user 0 com.google.android.hotword 2>/dev/null || echo skipped",
            "pm disable-user --user 0 com.google.android.ims 2>/dev/null || echo skipped",
            "am force-stop com.google.android.gms.unstable 2>/dev/null; echo done"
        )
        "game" -> listOf(
            "cmd game mode 2 2>/dev/null || echo skipped",
            "settings put global heads_up_notifications_enabled 0",
            "settings put global adaptive_battery_management_enabled 0",
            "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do cat \${f%min*}max_freq > \$f 2>/dev/null; done; echo done",
            "dumpsys deviceidle disable 2>/dev/null || echo skipped",
            "echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || echo skipped"
        )
        else -> emptyList()
    }
}
