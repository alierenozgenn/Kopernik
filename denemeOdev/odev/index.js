const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationToSeller = functions.firestore
    .document('supplies/{supplyId}/applicants/{applicantId}')
    .onCreate(async (snap, context) => {
        // Yeni başvuranın UID'sini al
        const applicantId = context.params.applicantId;

        // İlgili ürünün (supply) bilgilerini al
        const supplyId = context.params.supplyId;
        const supplyDoc = await admin.firestore().collection('supplies').doc(supplyId).get();
        if (!supplyDoc.exists) {
            console.error('Ürün bulunamadı:', supplyId);
            return null;
        }
        const supply = supplyDoc.data();
        const sellerId = supply.createdBy; // Satıcının UID'si
        const productTitle = supply.title; // Ürün adı

        // Başvuran kullanıcının bilgilerini al
        const applicantDoc = await admin.firestore().collection('users').doc(applicantId).get();
        if (!applicantDoc.exists) {
            console.error('Başvuran kullanıcı bulunamadı:', applicantId);
            return null;
        }
        const applicantName = applicantDoc.data().name || 'Bir müşteri';

        // Satıcının FCM token'ını al
        const sellerDoc = await admin.firestore().collection('users').doc(sellerId).get();
        if (!sellerDoc.exists) {
            console.error('Satıcı bulunamadı:', sellerId);
            return null;
        }
        const sellerToken = sellerDoc.data().fcmToken;
        if (!sellerToken) {
            console.error('Satıcının FCM token\'ı bulunamadı:', sellerId);
            return null;
        }

        // Bildirim mesajı oluştur
        const notification = {
            title: 'Yeni Başvuru!',
            body: `${applicantName}, ${productTitle} ürününüze başvurdu.`
        };



        // Bildirimi gönder
        try {
            await admin.messaging().send(message);
            console.log('Bildirim başarıyla gönderildi.');
        } catch (error) {
            console.error('Bildirim gönderilirken hata oluştu:', error);
        }
    });