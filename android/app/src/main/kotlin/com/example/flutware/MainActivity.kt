package uz.flutware.builder.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import com.android.apksig.ApkSigner
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Security
import java.security.cert.X509Certificate
import org.bouncycastle.jce.provider.BouncyCastleProvider
import org.bouncycastle.asn1.x500.X500Name
import org.bouncycastle.cert.jcajce.JcaX509CertificateConverter
import org.bouncycastle.cert.jcajce.JcaX509v3CertificateBuilder
import org.bouncycastle.operator.jcajce.JcaContentSignerBuilder
import java.math.BigInteger
import java.util.Date

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.flutware.builder/installer"

    init {
        Security.addProvider(BouncyCastleProvider())
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        installApk(path)
                        result.success(null)
                    } else {
                        result.error("INVALID_PATH", "Path is null", null)
                    }
                }
                "signApk" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    if (inputPath != null && outputPath != null) {
                        try {
                            signApk(inputPath, outputPath)
                            result.success(outputPath)
                        } catch (e: Exception) {
                            result.error("SIGN_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Args are null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private val KEYSTORE_NAME = "flutware_local.p12"
    private val PASSWORD = "flutware_secure".toCharArray()
    private val ALIAS = "flutware"

    private fun getOrCreateKeystore(): KeyStore {
        val file = File(filesDir, KEYSTORE_NAME)
        val ks = KeyStore.getInstance("PKCS12")
        
        if (file.exists()) {
            println("Lokal kalit yuklandi: ${file.absolutePath}")
            file.inputStream().use { ks.load(it, PASSWORD) }
        } else {
            println("Yangi lokal kalit yaratilmoqda...")
            ks.load(null, null)
            
            // RSA kalit juftligini yaratish
            val kpg = java.security.KeyPairGenerator.getInstance("RSA")
            kpg.initialize(2048)
            val kp = kpg.generateKeyPair()
            
            // Sertifikat yaratish (Soddalashtirilgan)
            val start = Date()
            val end = Date(start.time + 36500L * 24 * 60 * 60 * 1000) // 100 yil
            
            val dn = X500Name("CN=Flutware, O=Self, C=UZ")
            val serial = BigInteger.valueOf(System.currentTimeMillis())
            
            val contentSigner = JcaContentSignerBuilder("SHA256WithRSA").build(kp.private)
            val certBuilder = JcaX509v3CertificateBuilder(
                dn, serial, start, end, dn, kp.public
            )
            val cert = JcaX509CertificateConverter().getCertificate(certBuilder.build(contentSigner))
            
            ks.setKeyEntry(ALIAS, kp.private, PASSWORD, arrayOf(cert))
            
            file.outputStream().use { ks.store(it, PASSWORD) }
            println("Yangi lokal kalit saqlandi: ${file.absolutePath}")
        }
        return ks
    }

    private fun signApk(inputPath: String, outputPath: String) {
        println("SignApk boshlandi: $inputPath -> $outputPath")
        
        val ks = getOrCreateKeystore()
        val privateKey = ks.getKey(ALIAS, PASSWORD) as PrivateKey
        val cert = ks.getCertificate(ALIAS) as X509Certificate
        
        val signerConfig = ApkSigner.SignerConfig.Builder(ALIAS, privateKey, listOf(cert)).build()
        
        val builder = ApkSigner.Builder(listOf(signerConfig))
            .setInputApk(File(inputPath))
            .setOutputApk(File(outputPath))
            .setV1SigningEnabled(true)
            .setV2SigningEnabled(true)
            .setV3SigningEnabled(true)
            
        builder.build().sign()
        println("SignApk muvaffaqiyatli yakunlandi")
    }

    private fun installApk(path: String) {
        println("InstallApk boshlandi: $path")
        val file = File(path)
        if (!file.exists()) {
            println("XATOLIK: APK fayli topilmadi: $path")
            return
        }
        val intent = Intent(Intent.ACTION_VIEW)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            println("FileProvider URI: $uri")
            intent.setDataAndType(uri, "application/vnd.android.package-archive")
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } else {
            intent.setDataAndType(Uri.fromFile(file), "application/vnd.android.package-archive")
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }
}
