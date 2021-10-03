import { ic_assets } from "../../declarations/ic_assets";

document.getElementById("clickMeBtn").addEventListener("click", async () => {
  const name = document.getElementById("name").value.toString();
  // Interact with ic_assets actor, calling the greet method
  const greeting = await ic_assets.greet(name);

  document.getElementById("greeting").innerText = greeting;
});
