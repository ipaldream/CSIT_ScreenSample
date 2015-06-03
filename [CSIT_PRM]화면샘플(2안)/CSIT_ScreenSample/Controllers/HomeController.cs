using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace CSIT_ScreenSample.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult ProductSearch()
        {
            return View("ProductSearch");
        }

        public ActionResult ProductSearch2()
        {
            return View("ProductSearch2");
        }

        public ActionResult ProductDetail()
        {
            return View("ProductDetail");
        }

        public ActionResult TestPage()
        {
            return View("TestPage");
        }
    }
}