document.addEventListener("DOMContentLoaded", () => {
  const form = document.querySelector("#search-form");
  const queryInput = document.querySelector("#friend-search");
  const friendList = document.querySelector(".left-side .all-friends tbody");
  const searchButton = document.querySelector("#search-button");

  if (searchButton) {
    console.log("Search button:スコープ内1", searchButton);
    searchButton.addEventListener("click", async function (e) {
      e.preventDefault();
      console.log("test1");

      const query = queryInput.value;
      console.log("test2");

      const requestOptions = {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
        },
        body: JSON.stringify({ query: query }),
      };

      try {
        const response = await fetch("/friends/search", requestOptions);
        if (!response.ok) throw new Error("エラーが発生しました");

        const data = await response.json();
        console.log("test3", data);

        friendList.innerHTML = "";

        data.friends.forEach((friend) => {
          const friendRow = `
              <tr>
                <td>${friend.name}</td>
                <td>${friend.email}</td>
              </tr>
            `;
          friendList.innerHTML += friendRow;
        });
      } catch (error) {
        console.error("エラー", error);
      }
    });
  } else {
    console.log("test10");
    console.log("Search button:スコープ外", searchButton);
  }
});

