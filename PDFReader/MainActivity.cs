using Android.App;
using Android.OS;
using Android.Widget;
using Android.Content.PM;

namespace com.devsoftware.pdfreader
{
    [Activity(Label = "PDF Reader", MainLauncher = true, Icon = "@mipmap/ic_launcher", Theme = "@style/MainTheme",
              ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation)]
    public class MainActivity : Activity
    {
        protected override void OnCreate(Bundle savedInstanceState)
        {
            base.OnCreate(savedInstanceState);

            // layout yükle
            SetContentView(Resource.Layout.activity_main);

            var tv = FindViewById<TextView>(Resource.Id.mainText);
            tv.Text = "PDF Reader - hazır";
        }
    }
}
