window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.type === "showUI") {
        document.getElementById('overlay').style.display = data.display ? 'flex' : 'none';
    }

    if (data.type === "updateSpectators") {
        const list = document.getElementById('spectator-list');
        list.innerHTML = '';
        if (data.spectators.length > 0) {
            data.spectators.forEach(name => {
                const li = document.createElement('li');
                li.textContent = name;
                list.appendChild(li);
            });
        }
    }
});
