package com.example.expense_tracker; // change to your package

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.telephony.SmsMessage;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import android.app.PendingIntent;
import android.app.NotificationChannel;
import android.os.Build;

public class SmsReceiver extends BroadcastReceiver {
    private static final String CHANNEL_ID = "sms_channel";

    @Override
    public void onReceive(Context context, Intent intent) {
        Bundle bundle = intent.getExtras();
        if (bundle == null) return;

        Object[] pdus = (Object[]) bundle.get("pdus");
        if (pdus == null) return;

        for (Object pdu : pdus) {
            SmsMessage sms = SmsMessage.createFromPdu((byte[]) pdu);
            String sender = sms.getDisplayOriginatingAddress();
            String body = sms.getMessageBody();

            // Create notification with deep link
            createNotification(context, sender, body);
        }
    }

    private void createNotification(Context context, String sender, String body) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID, "SMS Notifications",
                android.app.NotificationManager.IMPORTANCE_HIGH
            );
            android.app.NotificationManager manager = context.getSystemService(android.app.NotificationManager.class);
            if (manager != null) manager.createNotificationChannel(channel);
        }

        // Deep link into Flutter with message data
        Intent launchIntent = new Intent(context, MainActivity.class);
        launchIntent.putExtra("sms_body", body);
        launchIntent.putExtra("sms_sender", sender);
        launchIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);

        PendingIntent pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

//        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, CHANNEL_ID)
//                .setSmallIcon(android.R.drawable.ic_dialog_info)
//                .setContentTitle("Expense Detected")
//                .setContentText(body)
//                .setStyle(new NotificationCompat.BigTextStyle().bigText(body))
//                .setPriority(NotificationCompat.PRIORITY_HIGH)
//                .setContentIntent(pendingIntent)
//                .setAutoCancel(true);

       // NotificationManagerCompat.from(context).notify((int) System.currentTimeMillis(), builder.build());
    }
}
